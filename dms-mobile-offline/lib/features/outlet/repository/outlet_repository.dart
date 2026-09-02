// ============================================================================
// Repository cho Outlet (điểm bán)
// ============================================================================

import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/outlet_dto.dart';
import '../models/value_set_model.dart';
import '../models/duplicate_check_model.dart';

/// Repository chịu trách nhiệm giao tiếp với backend Go REST API
class OutletRepository {
  final ApiClient apiClient;
  final SecureStorage storage;

  OutletRepository({
    required this.apiClient,
    required this.storage,
  }) {
    // Đọc token từ SecureStorage và inject vào ApiClient
    _initToken();
  }

  Future<void> _initToken() async {
    final token = await storage.readAccessToken();
    if (token != null) {
      apiClient.setAccessToken(token);
    }
  }

  /// Kiểm tra trùng lặp SĐT/Zalo/CCCD/MST/GPS
  /// Sử dụng stored procedure fn_check_duplicate_outlet trong PostgreSQL
  Future<DuplicateCheckResult> checkDuplicate({
    required String? phone,
    required String? zaloPhone,
    required String? taxCode,
    required String? identityCardNumber,
    required double? latitude,
    required double? longitude,
  }) async {
    // Xây dựng payload cho API check duplicate
    final Map<String, dynamic> payload = {
      'phone': phone?.trim(),
      'zalo_phone': zaloPhone?.trim(),
      'tax_code': taxCode?.trim(),
      'identity_card_number': identityCardNumber?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': 20, // bán kính 20m
    };
    // Loại bỏ các trường null để tránh lỗi validation
    payload.removeWhere((k, v) => v == null);
    final response = await apiClient.post('/api/v1/outlets/check-duplicate', body: payload);
    return DuplicateCheckResult.fromJson(response);
  }

  /// Tạo mới outlet
  Future<OutletCreateRequestDTO> createOutlet(OutletCreateRequestDTO dto) async {
    // Đảm bảo createdBy được gắn vào DTO (lấy từ session)
    final userId = await storage.readUserId();
    final dtoWithUser = dto.copyWith(createdBy: userId);

    final response = await apiClient.post('/api/v1/outlets', body: dtoWithUser.toJson());
    // Backend trả về object Outlet đã tạo
    // Có thể parse vào một model khác nếu cần
    return dtoWithUser; // Trả về DTO đã lưu
  }

  /// Upload ảnh mặt tiền (chuyển file thành multipart)
  Future<String> uploadPhoto(File photoFile) async {
    final userId = await storage.readUserId();
    final response = await apiClient.postMultipart(
      '/api/v1/outlets/upload-photo',
      fields: {'created_by': userId.toString()},
      files: [photoFile],
      fileFieldName: 'photo',
    );
    // Backend trả về URL ảnh đã lưu
    return response['data']['url'] ?? response['url'] ?? '';
  }

  /// Lấy danh sách ValueSetValue theo value_set_code (master data)
  /// Filter: delete_flg = '0', is_active = '1', hiệu lực hiện tại
  Future<List<ValueSetValueModel>> getValueSetValues(String valueSetCode) async {
    final response = await apiClient.get(
      '/api/v1/value-set-values',
      queryParams: {
        'value_set_code': valueSetCode,
        'is_active': true,
        'delete_flg': false,
        'now': DateTime.now().toIso8601String(), // backend sẽ dùng để filter hiệu lực
      },
    );
    final List<dynamic> list = response['data'] ?? response['value_set_values'] ?? [];
    return list.map((e) => ValueSetValueModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lấy danh sách provinces (tỉnh/thành phố)
  Future<List<AddressModel>> getProvinces() async {
    final response = await apiClient.get('/api/v1/provinces', queryParams: {
      'is_active': true,
      'delete_flg': false,
    });
    final List<dynamic> list = response['data'] ?? response['provinces'] ?? [];
    return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lấy districts theo province_code
  Future<List<AddressModel>> getDistrictsByProvince(String provinceCode) async {
    final response = await apiClient.get(
      '/api/v1/districts',
      queryParams: {
        'province_code': provinceCode,
        'is_active': true,
        'delete_flg': false,
      },
    );
    final List<dynamic> list = response['data'] ?? response['districts'] ?? [];
    return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lấy wards theo district_code
  Future<List<AddressModel>> getWardsByDistrict(String districtCode) async {
    final response = await apiClient.get(
      '/api/v1/wards',
      queryParams: {
        'district_code': districtCode,
        'is_active': true,
        'delete_flg': false,
      },
    );
    final List<dynamic> list = response['data'] ?? response['wards'] ?? [];
    return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Kiểm tra định dạng SĐT Việt Nam
  bool isValidVietnamPhone(String phone) {
    final pattern = r'^(?:\+84|0)[35789]\d{8}$';
    return RegExp(pattern).hasMatch(phone?.replaceAll(' ', '') ?? '');
  }

  /// Kiểm tra định dạng Zalo (giống SĐT VN)
  bool isValidZalo(String zalo) => isValidVietnamPhone(zalo);

  /// Kiểm tra định dạng CCCD/CMND (12 số cho CCCD, 9 số cho CMND cũ)
  bool isValidIdCard(String idCard) {
    final cleaned = idCard?.replaceAll(' ', '') ?? '';
    return RegExp(r'^\d{9}$|^\d{12}$').hasMatch(cleaned);
  }

  /// Kiểm tra định dạng mã số thuế (10 hoặc 13 số)
  bool isValidTaxCode(String taxCode) {
    final cleaned = taxCode?.replaceAll(' ', '') ?? '';
    return RegExp(r'^\d{10}$|^\d{13}$').hasMatch(cleaned);
  }
}