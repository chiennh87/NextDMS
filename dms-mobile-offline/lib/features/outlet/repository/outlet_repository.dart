// OutletRepository - giao tiep voi backend Go REST API
// Enterprise: Scoping, Sync, Multi-Country

import 'dart:io';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/outlet_dto.dart';
import '../models/value_set_model.dart';
import '../models/address_model.dart';
import '../models/duplicate_check_model.dart';

class OutletRepository {
  final ApiClient apiClient;
  final SecureStorage storage;

  OutletRepository({required this.apiClient, required this.storage}) {
    _initToken();
  }

  Future<void> _initToken() async {
    final token = await storage.readAccessToken();
    if (token != null) apiClient.setAccessToken(token);
  }

  // Enterprise: Duplicate Detection voi Scoping (Data Isolation)
  Future<DuplicateCheckResult> checkDuplicate({
    required String? phone,
    required String? zaloPhone,
    required String? taxCode,
    required String? identityCardNumber,
    required double? latitude,
    required double? longitude,
    int? distributorId,
    int? territoryId,
  }) async {
    final Map<String, dynamic> payload = {
      'phone': phone?.trim(), 'zalo_phone': zaloPhone?.trim(),
      'tax_code': taxCode?.trim(), 'identity_card_number': identityCardNumber?.trim(),
      'latitude': latitude, 'longitude': longitude,
      'radius_meters': 20,
      'distributor_id': distributorId ?? 1,
      'territory_id': territoryId ?? 1,
    };
    payload.removeWhere((k, v) => v == null);
    final response = await apiClient.post('/outlets/check-duplicate', body: payload);
    return DuplicateCheckResult.fromJson(response);
  }
}
  // Enterprise: Create Outlet voi Scoping + Approval Workflow
  Future<OutletCreateRequestDTO> createOutlet(OutletCreateRequestDTO dto) async {
    final userId = await storage.readUserIdInt();
    final dtoWithAudit = dto.copyWith(
      createdBy: userId,
      approvalStatus: dto.approvalStatus ?? "PENDING_APPROVAL",
      syncStatus: dto.syncStatus ?? "PENDING",
      countryCode: dto.countryCode ?? "VNM",
    );
    await apiClient.post("/outlets", body: dtoWithAudit.toJson());
    return dtoWithAudit;
  }

  // Enterprise: Upload Photo - chi tra ve CDN URL
  Future<String> uploadPhoto(File photoFile) async {
    final userId = await storage.readUserId() ?? "0";
    final response = await apiClient.postMultipart(
      "/outlets/upload-photo",
      fields: {"created_by": userId},
      files: [photoFile],
      fileFieldName: "photo",
    );
    final data = response["data"];
    if (data is Map && data["url"] != null) return data["url"].toString();
    if (response["url"] != null) return response["url"].toString();
    if (response["photo_url"] != null) return response["photo_url"].toString();
    return "";
  }

  // Enterprise: Master Data voi Multi-Country
  Future<List<ValueSetValueModel>> getValueSetValues(String valueSetCode, {String countryCode = "VNM"}) async {
    final response = await apiClient.get("/value-set-values", queryParams: {
      "value_set_code": valueSetCode, "is_active": "1", "delete_flg": "0", "country_code": countryCode,
    });
    final List<dynamic> list = response["data"] ?? response["value_set_values"] ?? [];
    return list.map((e) => ValueSetValueModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AddressModel>> getProvinces({String countryCode = "VNM"}) async {
    final response = await apiClient.get("/provinces", queryParams: {
      "is_active": "1", "delete_flg": "0", "country_code": countryCode,
    });
    final List<dynamic> list = response["data"] ?? response["provinces"] ?? [];
    return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AddressModel>> getDistrictsByProvince(String provinceCode, {String countryCode = "VNM"}) async {
    final response = await apiClient.get("/districts", queryParams: {
      "province_code": provinceCode, "is_active": "1", "delete_flg": "0", "country_code": countryCode,
    });
    final List<dynamic> list = response["data"] ?? response["districts"] ?? [];
    return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AddressModel>> getWardsByDistrict(String districtCode, {String countryCode = "VNM"}) async {
    final response = await apiClient.get("/wards", queryParams: {
      "district_code": districtCode, "is_active": "1", "delete_flg": "0", "country_code": countryCode,
    });
    final List<dynamic> list = response["data"] ?? response["wards"] ?? [];
    return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Enterprise: Sync Methods
  Future<List<Map<String, dynamic>>> getPendingSyncOutlets({required int distributorId, required int territoryId}) async {
    final response = await apiClient.get("/outlets/pending-sync", queryParams: {
      "distributor_id": distributorId.toString(),
      "territory_id": territoryId.toString(),
    });
    return (response["data"] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<bool> syncOutlet(Map<String, dynamic> payload) async {
    final resp = await apiClient.post("/outlets/sync", body: payload);
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  Future<void> updateSyncStatus({required String localId, required String syncStatus, String? errorLog}) async {
    await apiClient.patch("/outlets/sync-status", body: {
      "local_id": localId,
      "sync_status": syncStatus,
      if (errorLog != null) "sync_error_log": errorLog,
    });
  }

  // Validation helpers (VN)
  bool isValidVietnamPhone(String phone) {
    final cleaned = phone.replaceAll(" ", "").replaceAll(".", "");
    return RegExp(r"^(?:\+84|0)[35789]\d{8}$").hasMatch(cleaned);
  }

  bool isValidZalo(String zalo) => isValidVietnamPhone(zalo);

  bool isValidIdCard(String idCard) {
    final cleaned = idCard.replaceAll(" ", "");
    return RegExp(r"^\d{9}$|^\d{12}$").hasMatch(cleaned);
  }

  bool isValidTaxCode(String taxCode) {
    final cleaned = taxCode.replaceAll(" ", "").replaceAll("-", "");
    return RegExp(r"^\d{10}$|^\d{13}$").hasMatch(cleaned);
  }
}
