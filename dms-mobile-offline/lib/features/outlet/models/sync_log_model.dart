// ============================================================================
// SyncLog Model - Ghi nhan loi dong bo
// ============================================================================

import 'dart:convert';

/// Bang sync log tren server - ghi nhan loi/than cong sync
class SyncLogModel {
  final int? id;
  final String tableName;
  final String? localId;
  final int? serverId;
  final String action; // INSERT, UPDATE, DELETE
  final Map<String, dynamic>? payload;
  final String syncStatus; // PENDING, SYNCING, SYNCED, FAILED, CONFLICT
  final String? errorMessage;
  final int retryCount;
  final int createdBy;
  final DateTime? creationDate;
  final DateTime? lastSyncAttempt;
  final DateTime? resolvedAt;
  final String? resolutionStrategy; // SERVER_WINS, CLIENT_WINS, MERGED

  SyncLogModel({
    this.id,
    required this.tableName,
    this.localId,
    this.serverId,
    required this.action,
    this.payload,
    this.syncStatus = 'PENDING',
    this.errorMessage,
    this.retryCount = 0,
    required this.createdBy,
    this.creationDate,
    this.lastSyncAttempt,
    this.resolvedAt,
    this.resolutionStrategy,
  });

  factory SyncLogModel.fromJson(Map<String, dynamic> json) {
    return SyncLogModel(
      id: json['id'] as int?,
      tableName: json['table_name'] as String? ?? 'tblOutlets',
      localId: json['local_id'] as String?,
      serverId: json['server_id'] as int?,
      action: json['action'] as String? ?? 'INSERT',
      payload: json['payload'] != null ? jsonDecode(json['payload'] as String) as Map<String, dynamic> : null,
      syncStatus: json['sync_status'] as String? ?? 'PENDING',
      errorMessage: json['error_message'] as String?,
      retryCount: json['retry_count'] as int? ?? 0,
      createdBy: json['created_by'] as int? ?? 0,
      creationDate: json['creation_date'] != null ? DateTime.tryParse(json['creation_date'] as String) : null,
      lastSyncAttempt: json['last_sync_attempt'] != null ? DateTime.tryParse(json['last_sync_attempt'] as String) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'] as String) : null,
      resolutionStrategy: json['resolution_strategy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'table_name': tableName,
      'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      'action': action,
      if (payload != null) 'payload': jsonEncode(payload),
      'sync_status': syncStatus,
      'error_message': errorMessage,
      'retry_count': retryCount,
      'created_by': createdBy,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt!.toIso8601String(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      'resolution_strategy': resolutionStrategy,
    };
  }

  SyncLogModel copyWith({
    int? id,
    String? tableName,
    String? localId,
    int? serverId,
    String? action,
    Map<String, dynamic>? payload,
    String? syncStatus,
    String? errorMessage,
    int? retryCount,
    int? createdBy,
    DateTime? creationDate,
    DateTime? lastSyncAttempt,
    DateTime? resolvedAt,
    String? resolutionStrategy,
  }) {
    return SyncLogModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdBy: createdBy ?? this.createdBy,
      creationDate: creationDate ?? this.creationDate,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionStrategy: resolutionStrategy ?? this.resolutionStrategy,
    );
  }
}