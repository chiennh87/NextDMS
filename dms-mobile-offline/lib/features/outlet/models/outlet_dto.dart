// ============================================================================
// Outlet DTO - Data Transfer Object for Create Outlet
// ============================================================================

import 'package:equatable/equatable.dart';

/// DTO gửi lên backend khi tạo Outlet mới
class OutletCreateRequestDTO extends Equatable {
  // Thông tin chung
  final String? name;
  final String? shortName;            // Tên chủ cửa hàng
  final DateTime? ownerDob;          // Ngày sinh chủ cửa hàng

  // Thông tin liên hệ & định danh
  final String? phone;
  final String? zaloPhone;
  final String? identityCardNumber;

  // Thông tin pháp lý
  final String? businessType;        // DOANH_NGHIEP / HOP_KINH_DOANH
  final String? businessLicenseNo;
  final String? taxCode;

  // Địa chỉ (cascading)
  final String? provinceCode;
  final String? districtCode;
  final String? wardCode;
  final String? streetNumber;
  final String? streetName;

  // GPS
  final double? latitude;
  final double? longitude;

  // Ảnh mặt tiền
  final String? photoUrl;

  // Master data codes
  final String? customerTypeCode;    // CUSTOMER_TYPE
  final String? customerChannelCode; // CUSTOMER_CHANNEL
  final String? tier;                // GOLD / SILVER / BRONZE
  final int? mcpId;

  // Audit
  final int? createdBy;              // Lấy từ Session/Token

  const OutletCreateRequestDTO({
    this.name,
    this.shortName,
    this.ownerDob,
    this.phone,
    this.zaloPhone,
    this.identityCardNumber,
    this.businessType,
    this.businessLicenseNo,
    this.taxCode,
    this.provinceCode,
    this.districtCode,
    this.wardCode,
    this.streetNumber,
    this.streetName,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.customerTypeCode,
    this.customerChannelCode,
    this.tier,
    this.mcpId,
    this.createdBy,
  });

  /// Copy with để cập nhật từng trường
  OutletCreateRequestDTO copyWith({
    String? name,
    String? shortName,
    DateTime? ownerDob,
    String? phone,
    String? zaloPhone,
    String? identityCardNumber,
    String? businessType,
    String? businessLicenseNo,
    String? taxCode,
    String? provinceCode,
    String? districtCode,
    String? wardCode,
    String? streetNumber,
    String? streetName,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? customerTypeCode,
    String? customerChannelCode,
    String? tier,
    int? mcpId,
    int? createdBy,
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
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Convert sang JSON để gửi lên backend Go
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'short_name': shortName,
      if (ownerDob != null) 'owner_dob': ownerDob!.toIso8601String().split('T')[0],
      'phone': phone,
      'zalo_phone': zaloPhone,
      'identity_card_number': identityCardNumber,
      'business_type': businessType,
      'business_license_no': businessLicenseNo,
      'tax_code': taxCode,
      'province_code': provinceCode,
      'district_code': districtCode,
      'ward_code': wardCode,
      'street_number': streetNumber,
      'street_name': streetName,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'customer_type_code': customerTypeCode,
      'customer_channel_code': customerChannelCode,
      'tier': tier,
      'mcp_id': mcpId,
      'created_by': createdBy,
      'status': 'PENDING_VERIFICATION',
    };
  }

  @override
  List<Object?> get props => [
    name, shortName, ownerDob, phone, zaloPhone,
    identityCardNumber, businessType, businessLicenseNo, taxCode,
    provinceCode, districtCode, wardCode, streetNumber, streetName,
    latitude, longitude, photoUrl, customerTypeCode, customerChannelCode,
    tier, mcpId, createdBy,
  ];
}