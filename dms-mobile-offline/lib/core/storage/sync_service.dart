// SyncService - Background Auto-Retry voi Connectivity Listening
// Enterprise: Offline-First Strategy

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../api/api_client.dart';

enum SyncState {
  idle,
  syncing,
  success,
  failed,
  offline,
}

class SyncResult {
  final bool success;
  final String? error;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    this.error,
    this.syncedCount = 0,
    this.failedCount = 0,
  });
}
class SyncService {
  final ApiClient apiClient;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;

  SyncState _state = SyncState.idle;
  SyncState get state => _state;

  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _initialRetryDelay = Duration(seconds: 30);

  VoidCallback? onSyncStarted;
  void Function(SyncResult)? onSyncCompleted;
  void Function(SyncResult)? onSyncFailed;

  SyncService({required this.apiClient}) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final hasInternet = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (hasInternet) {
        await _onConnectivityRestored();
      } else {
        _state = SyncState.offline;
        _scheduleRetry();
      }
    });
  }

  Future<void> _onConnectivityRestored() async {
    if (_state == SyncState.syncing) return;
    await Future.delayed(const Duration(seconds: 2));
    await syncPending();
  }

  Future<SyncResult> syncPending() async {
    if (_state == SyncState.syncing) {
      return SyncResult(success: false, error: "Dang dong bo");
    }
    _state = SyncState.syncing;
    onSyncStarted?.call();
    try {
      final pending = await _fetchPendingItems();
      if (pending.isEmpty) {
        _state = SyncState.success;
        _retryCount = 0;
        final result = SyncResult(success: true, syncedCount: 0);
        onSyncCompleted?.call(result);
        return result;
      }
      int synced = 0;
      int failed = 0;
      String? lastError;
      for (final item in pending) {
        try {
          final success = await _syncItem(item);
          if (success) {
            synced++;
            await _markSynced(item["local_id"] as String);
          } else {
            failed++;
            lastError = "Sync item failed";
          }
        } catch (e) {
          failed++;
          lastError = e.toString();
          await _markFailed(item["local_id"] as String, e.toString());
        }
      }
      if (failed > 0) {
        _state = SyncState.failed;
        _retryCount++;
        _scheduleRetry();
        final result = SyncResult(success: false, error: lastError, syncedCount: synced, failedCount: failed);
        onSyncFailed?.call(result);
        return result;
      } else {
        _state = SyncState.success;
        _retryCount = 0;
        final result = SyncResult(success: true, syncedCount: synced);
        onSyncCompleted?.call(result);
        return result;
      }
    } catch (e) {
      _state = SyncState.failed;
      _retryCount++;
      _scheduleRetry();
      final result = SyncResult(success: false, error: e.toString());
      onSyncFailed?.call(result);
      return result;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPendingItems() async {
    try {
      final resp = await apiClient.get("/outlets/pending-sync");
      if (resp.statusCode == 200) {
        final data = resp.data as List<dynamic>?;
        return data?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (e) {
      debugPrint("[SyncService] Fetch pending failed: " + e.toString());
    }
    return [];
  }

  Future<bool> _syncItem(Map<String, dynamic> item) async {
    try {
      final resp = await apiClient.post("/outlets/sync", data: item);
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> _markSynced(String localId) async {
    try {
      await apiClient.patch("/outlets/sync-status", data: {"local_id": localId, "sync_status": "SYNCED"});
    } catch (_) {}
  }

  Future<void> _markFailed(String localId, String error) async {
    try {
      await apiClient.patch("/outlets/sync-status", data: {"local_id": localId, "sync_status": "FAILED", "sync_error_log": error});
    } catch (_) {}
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetries) return;
    // Exponential backoff: 30s -> 60s -> 120s -> 240s -> 480s
    final delay = _initialRetryDelay * (1 << _retryCount);
    debugPrint("[SyncService] Retry in " + delay.inSeconds.toString() + "s (attempt " + (_retryCount + 1).toString() + ")");
    _retryTimer = Timer(delay, () {
      syncPending();
    });
  }

  Future<SyncResult> retryNow() async {
    _retryTimer?.cancel();
    _retryCount = 0;
    return syncPending();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
  }
}
