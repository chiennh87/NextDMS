// ============================================================================
// Sync Status Banner - Offline-First Sync UI Component
// ============================================================================

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../bloc/outlet_onboarding_state.dart';

/// Banner hiển thị trạng thái offline/sync
class SyncStatusBanner extends StatefulWidget {
  final OutletOnboardingState state;
  final VoidCallback? onSyncTap;
  final VoidCallback? onRetryTap;

  const SyncStatusBanner({
    super.key,
    required this.state,
    this.onSyncTap,
    this.onRetryTap,
  });

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      final online = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = online);
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state is OutletDraftSaved) {
      return _buildDraftSavedBanner(widget.state as OutletDraftSaved);
    }
    if (widget.state is OutletSyncing) {
      return _buildSyncingBanner(widget.state as OutletSyncing);
    }
    if (widget.state is OutletSyncCompleted) {
      return _buildSyncCompletedBanner(widget.state as OutletSyncCompleted);
    }
    if (!_isOnline) {
      return _buildOfflineBanner();
    }
    return const SizedBox.shrink();
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade700,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Ban dang offline - Du lieu se dong bo khi co mang',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/outlet/drafts'),
            child: const Text('Xem nhap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }



/// Widget hiển thị sync status badge trên outlet card
class SyncStatusBadge extends StatelessWidget {
  final String syncStatus;
  final String? syncError;

  const SyncStatusBadge({super.key, required this.syncStatus, this.syncError});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (syncStatus.toUpperCase()) {
      'SYNCED' => (Icons.cloud_done, Colors.green, 'Da dong bo'),
      'SYNCING' => (Icons.cloud_sync, Colors.blue, 'Dang dong bo'),
      'PENDING' => (Icons.cloud_upload, Colors.orange, 'Cho dong bo'),
      'FAILED' => (Icons.cloud_off, Colors.red, 'Loi dong bo'),
      _ => (Icons.cloud_queue, Colors.grey, 'Khong ro'),
    };

    return Tooltip(
      message: syncError ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị approval status badge
class ApprovalStatusBadge extends StatelessWidget {
  final String approvalStatus;

  const ApprovalStatusBadge({super.key, required this.approvalStatus});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bgColor, label) = switch (approvalStatus.toUpperCase()) {
      'APPROVED' => (Icons.check_circle, Colors.green, Colors.green.shade50, 'Da duyet'),
      'PENDING_APPROVAL' => (Icons.pending, Colors.orange, Colors.orange.shade50, 'Cho duyet'),
      'REJECTED' => (Icons.cancel, Colors.red, Colors.red.shade50, 'Tu choi'),
      'DRAFT' => (Icons.edit_note, Colors.grey, Colors.grey.shade50, 'Nhap'),
      _ => (Icons.help, Colors.grey, Colors.grey.shade50, 'Khong ro'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
  Widget _buildDraftSavedBanner(OutletDraftSaved state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.save, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Da luu nhap thanh cong!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (_isOnline)
                TextButton.icon(
                  onPressed: widget.onSyncTap,
                  icon: const Icon(Icons.cloud_upload, color: Colors.white, size: 16),
                  label: const Text('Dong bo ngay', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Ma nhap: ${state.localId.substring(0, 8)}... | Da dong bo: 0',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSyncingBanner(OutletSyncing state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.indigo.shade600,
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dang dong bo...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Dang xu ly ${state.pendingCount} muc', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (_isOnline) const Icon(Icons.cloud_sync, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildSyncCompletedBanner(OutletSyncCompleted state) {
    final allSuccess = state.failedCount == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: allSuccess ? Colors.green.shade600 : Colors.red.shade600,
      child: Row(
        children: [
          Icon(allSuccess ? Icons.check_circle : Icons.warning, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(allSuccess ? 'Dong bo thanh cong!' : 'Dong bo co loi',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Thanh cong: ${state.syncedCount} | That bai: ${state.failedCount}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (!allSuccess && state.failedCount > 0)
            TextButton(onPressed: widget.onRetryTap, child: const Text('Thu lai', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}