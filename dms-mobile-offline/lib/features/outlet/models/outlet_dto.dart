// Outlet DTO - Data Transfer Object for Create Outlet
// Enterprise: Approval Workflow, Offline-First Sync, Multi-Country, Data Scoping

import 'package:equatable/equatable.dart';

class OutletCreateRequestDTO extends Equatable {
  // Thong tin chung
  final String? name;
  final String? shortName;
  final DateTime? ownerDob;
  // Lien he & dinh danh
  final String? phone;
  final String? zaloPhone;
  final String? identityCardNumber;
  // Phap ly
  final String? businessType;
  final String? businessLicenseNo;
  final String? taxCode;
  // Dia chi
  final String? provinceCode;
  final String? districtCode;
  final String? wardCode;
  final String? streetNumber;
  final String? streetName;
  // GPS
  final double? latitude;
  final double? longitude;
  // Media
  final String? photoUrl;
  // Master data
  final String? customerTypeCode;
  final String? customerChannelCode;
  final String? tier;
  final int? mcpId;
  // Enterprise: Scoping
  final int? distributorId;
  final int? territoryId;
  // Enterprise: Approval
  final String? approvalStatus;
  final int? approvedBy;
  final DateTime? approvalDate;
  final String? rejectedReason;
  // Enterprise: Sync
  final String? syncStatus;
  final String? localId;
  final String? syncErrorLog;
  // Enterprise: Multi-Country
  final String? countryCode;
  // Audit
  final int? createdBy;

  const OutletCreateRequestDTO({
    this.name, this.shortName, this.ownerDob,
    this.phone, this.zaloPhone, this.identityCardNumber,
    this.businessType, this.businessLicenseNo, this.taxCode,
    this.provinceCode, this.districtCode, this.wardCode,
    this.streetNumber, this.streetName,
    this.latitude, this.longitude, this.photoUrl,
    this.customerTypeCode, this.customerChannelCode, this.tier, this.mcpId,
    this.distributorId, this.territoryId,
    this.approvalStatus, this.approvedBy, this.approvalDate, this.rejectedReason,
    this.syncStatus, this.localId, this.syncErrorLog,
    this.countryCode, this.createdBy,
  });
}
  /// Copy with de cap nhat tung truong
  OutletCreateRequestDTO copyWith({
    String? name, String? shortName, DateTime? ownerDob,
    String? phone, String? zaloPhone, String? identityCardNumber,
    String? businessType, String? businessLicenseNo, String? taxCode,
    String? provinceCode, String? districtCode, String? wardCode,
    String? streetNumber, String? streetName,
    double? latitude, double? longitude, String? photoUrl,
    String? customerTypeCode, String? customerChannelCode, String? tier, int? mcpId,
    int? distributorId, int? territoryId,
    String? approvalStatus, int? approvedBy, DateTime? approvalDate, String? rejectedReason,
    String? syncStatus, String? localId, String? syncErrorLog,
    String? countryCode, int? createdBy,
  }) {
    return OutletCreateRequestDTO(
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      ownerDob: ownerDob ?? this.ownerDob,
      phone: phone ?? this.phone,
      zaloPhone: zaloPhone ?? this.zaloPhone,
      identityCardNumber: identityCardNumber ?? this.identityCardNumber,
      businessType: businessType ?? this.businessType,
      businessLicenseNo: businessLicenseNo ?? this.businessLicenseNo,
      taxCode: taxCode ?? this.taxCode,
      provinceCode: provinceCode ?? this.provinceCode,
      districtCode: districtCode ?? this.districtCode,
      wardCode: wardCode ?? this.wardCode,
      streetNumber: streetNumber ?? this.streetNumber,
      streetName: streetName ?? this.streetName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      customerTypeCode: customerTypeCode ?? this.customerTypeCode,
      customerChannelCode: customerChannelCode ?? this.customerChannelCode,
      tier: tier ?? this.tier,
      mcpId: mcpId ?? this.mcpId,
      distributorId: distributorId ?? this.distributorId,
      territoryId: territoryId ?? this.territoryId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvalDate: approvalDate ?? this.approvalDate,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      syncStatus: syncStatus ?? this.syncStatus,
      localId: localId ?? this.localId,
      syncErrorLog: syncErrorLog ?? this.syncErrorLog,
      countryCode: countryCode ?? this.countryCode,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Convert sang JSON - UTF-8 encoding (Flutter default)
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "short_name": shortName,
      if (ownerDob != null) "owner_dob": ownerDob!.toIso8601String().split("T")[0],
      "phone": phone,
      "zalo_phone": zaloPhone,
      "identity_card_number": identityCardNumber,
      "business_type": businessType,
      "business_license_no": businessLicenseNo,
      "tax_code": taxCode,
      "province_code": provinceCode,
      "district_code": districtCode,
      "ward_code": wardCode,
      "street_number": streetNumber,
      "street_name": streetName,
      "latitude": latitude,
      "longitude": longitude,
      "photo_url": photoUrl,
      "customer_type_code": customerTypeCode,
      "customer_channel_code": customerChannelCode,
      "tier": tier,
      "mcp_id": mcpId,
      "distributor_id": distributorId,
      "territory_id": territoryId,
      "approval_status": approvalStatus ?? "PENDING_APPROVAL",
      "approved_by": approvedBy,
      if (approvalDate != null) "approval_date": approvalDate!.toIso8601String(),
      "rejected_reason": rejectedReason,
      "sync_status": syncStatus ?? "PENDING",
      "local_id": localId,
      "sync_error_log": syncErrorLog,
      "country_code": countryCode ?? "VNM",
      "created_by": createdBy,
      "status": "PENDING_VERIFICATION",
    };
  }

  @override
  List<Object?> get props => [
    name, shortName, ownerDob, phone, zaloPhone, identityCardNumber,
    businessType, businessLicenseNo, taxCode,
    provinceCode, districtCode, wardCode, streetNumber, streetName,
    latitude, longitude, photoUrl,
    customerTypeCode, customerChannelCode, tier, mcpId,
    distributorId, territoryId, approvalStatus, approvedBy, approvalDate, rejectedReason,
    syncStatus, localId, syncErrorLog, countryCode, createdBy,
  ];
}
