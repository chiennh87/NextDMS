// ============================================================================
// Outlet Model (Data Models)
// ============================================================================

import 'dart:
    convert';
import 'package:equatable/equatable.dart';

/// Model cho thông tin điểm bán (Outlet)
class OutletModel extends Equatable {
  final int? id;
  final String? code;
  final String? name;
  final String? shortName;
  final DateTime? ownerDob;
  final String? phone;
  final String? zaloPhone;
  final String? identityCardNumber;
  final String? businessType;
  final String? businessLicenseNo;
  final String? taxCode;
  final String? address;
  final String? provinceCode;
  final String? districtCode;
  final String? wardCode;
  final String? streetNumber;
  final String? streetName;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? customerTypeCode;
  final String? customerChannelCode;
  final String? tier;
  final int? mcpId;
  final String? status;
  final bool? deleteFlg;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? creationDate;
  final DateTime? lastUpdateDate;
}

/// DTO cho yêu cầu tạo điểm bán (Outbound)
class OutletCreateRequestDTO extends Equatable {
  final String? code;
  final String? name;
  final String? shortName;
  final DateTime? ownerDob;
  final String? phone;
  final String? zaloPhone;
  final String? identityCardNumber;
  final String? businessType;
  final String? businessLicenseNo;
  final String? taxCode;
  final String? address;
  final String? provinceCode;
  final String? districtCode;
  final String? wardCode;
  final String? streetNumber;
  final String? streetName;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? customerTypeCode;
  final String? customerChannelCode;
  final String? tier;
  final int? mcpId;
  final String? status;
  final bool? deleteFlg;
  final int? createdBy;
  final int? updatedBy;
}

/// Model cho trạng thái (State) trong BLoC
enum OutletStatus {
  PendingVerification,
  Active,
  Rejected,
  Archived,
}

/// Event cho việc tạo điểm bán
abstract class OutletOnboardingEvent extends Equatable {
  const OutletOnboardingEvent();
  const OutletOnboardingEvent(String? message);
}

/// Event cho việc kiểm tra trùng lặp
abstract class DuplicateCheckEvent extends Equatable {
  const DuplicateCheckEvent();
  const DuplicateCheckEvent(String? message);
}

/// Event cho việc tạo điểm bán thành công
abstract class OutletCreatedEvent extends Equatable {
  final int? outletId;
  final String? code;
  final String? name;
  final String? shortName;
  final DateTime? createdAt;
  final bool? deleted;
  const OutletCreatedEvent();
  const OutletCreatedEvent(int? outletId, String? code, String? name, String? shortName, DateTime? createdAt, bool? deleted);
}

/// Event cho việc xóa điểm bán
abstract class OutletDeletedEvent extends Equatable {
  final int? outletId;
  final String? reason;
  const OutletDeletedEvent();
  const OutletDeletedEvent(int? outletId, String? reason);
}

/// Event cho việc cập nhật điểm bán
abstract class OutletUpdatedEvent extends Equatable {
  final int? outletId;
  final Map<String, dynamic> updates;
  const OutletUpdatedEvent();
  const OutletUpdatedEvent(int? outletId, Map<String, dynamic> updates);
}

/// Event cho việc xóa điểm bán (soft delete)
abstract class OutletSoftDeletedEvent extends Equatable {
  final int? outletId;
  final String? reason;
  const OutletSoftDeletedEvent();
  const OutletSoftDeletedEvent(int? outletId, String? reason);
}
