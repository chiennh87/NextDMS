// ============================================================================
// Enums cho Outlet - dung chung cho ca enterprise features
// ============================================================================

/// Trang thai phe duyet diem ban (Approval Workflow)
/// - DRAFT: ban nhap dang soan, chua gui
/// - PENDING_APPROVAL: da gui cho SS/ASM duyet
/// - APPROVED: da duyet, cho phep dat don hang
/// - REJECTED: bi tu choi, can sua lai
enum OutletApprovalStatus {
  draft,
  pendingApproval,
  approved,
  rejected;

  String get apiValue {
    switch (this) {
      case OutletApprovalStatus.draft:
        return 'DRAFT';
      case OutletApprovalStatus.pendingApproval:
        return 'PENDING_APPROVAL';
      case OutletApprovalStatus.approved:
        return 'APPROVED';
      case OutletApprovalStatus.rejected:
        return 'REJECTED';
    }
  }

  String get displayName {
    switch (this) {
      case OutletApprovalStatus.draft:
        return 'Ban nhap';
      case OutletApprovalStatus.pendingApproval:
        return 'Cho duyet';
      case OutletApprovalStatus.approved:
        return 'Da duyet';
      case OutletApprovalStatus.rejected:
        return 'Bi tu choi';
    }
  }

  static OutletApprovalStatus fromApi(String? value) {
    switch (value) {
      case 'DRAFT':
        return OutletApprovalStatus.draft;
      case 'APPROVED':
        return OutletApprovalStatus.approved;
      case 'REJECTED':
        return OutletApprovalStatus.rejected;
      case 'PENDING_APPROVAL':
      default:
        return OutletApprovalStatus.pendingApproval;
    }
  }
}

/// Trang thai dong bo (Offline-First)
/// - PENDING: ban ghi offline, cho sync
/// - SYNCING: dang sync
/// - SYNCED: da sync thanh cong
/// - FAILED: sync that bai, can retry
enum OutletSyncStatus {
  pending,
  syncing,
  synced,
  failed;

  String get apiValue {
    switch (this) {
      case OutletSyncStatus.pending:
        return 'PENDING';
      case OutletSyncStatus.syncing:
        return 'SYNCING';
      case OutletSyncStatus.synced:
        return 'SYNCED';
      case OutletSyncStatus.failed:
        return 'FAILED';
    }
  }

  String get displayName {
    switch (this) {
      case OutletSyncStatus.pending:
        return 'Cho dong bo';
      case OutletSyncStatus.syncing:
        return 'Dang dong bo...';
      case OutletSyncStatus.synced:
        return 'Da dong bo';
      case OutletSyncStatus.failed:
        return 'Dong bo loi';
    }
  }

  static OutletSyncStatus fromApi(String? value) {
    switch (value) {
      case 'PENDING':
        return OutletSyncStatus.pending;
      case 'SYNCING':
        return OutletSyncStatus.syncing;
      case 'SYNCED':
        return OutletSyncStatus.synced;
      case 'FAILED':
        return OutletSyncStatus.failed;
      default:
        return OutletSyncStatus.synced;
    }
  }
}

/// Ma quoc gia (Multi-Country Support)
enum CountryCode {
  vnm('VNM', 'Viet Nam'),
  lao('LAO', 'Lao'),
  cam('CAM', 'Campuchia'),
  mmr('MMR', 'Myanmar');

  final String code;
  final String name;
  const CountryCode(this.code, this.name);

  static CountryCode fromCode(String? code) {
    switch (code) {
      case 'LAO':
        return CountryCode.lao;
      case 'CAM':
        return CountryCode.cam;
      case 'MMR':
        return CountryCode.mmr;
      case 'VNM':
      default:
        return CountryCode.vnm;
    }
  }
}

/// Chien luoc giai quyet xung dot khi sync
enum ConflictResolution {
  serverWins,
  clientWins,
  merged;

  String get apiValue {
    switch (this) {
      case ConflictResolution.serverWins:
        return 'SERVER_WINS';
      case ConflictResolution.clientWins:
        return 'CLIENT_WINS';
      case ConflictResolution.merged:
        return 'MERGED';
    }
  }
}