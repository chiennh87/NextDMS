// ============================================================================
// Value Set Model (Master Data from tblValueSetValue)
// ============================================================================

import 'package:equatable/equatable.dart';

/// Model cho tblValueSetValue - chứa thông tin từng giá trị trong master data
class ValueSetValueModel extends Equatable {
  final int? id;
  final String? valueSetCode;       // Ví dụ: 'CUSTOMER_TYPE', 'CUSTOMER_CHANNEL'
  final String? code;               // value_code trong DB
  final String? name;               // value_name trong DB
  final String? parentCode;         // parent_code cho cascade
  final int? displayOrder;
  final int? sortOrder;
  final String? description;
  final bool? isActive;             // is_active CHAR(1)
  final bool? deleteFlg;            // delete_flg CHAR(1)
  final DateTime? effectiveFrom;    // effective_from TIMESTAMPTZ
  final DateTime? effectiveTo;      // effective_to TIMESTAMPTZ
  final int? createdBy;
  final int? updatedBy;
  final DateTime? creationDate;
  final DateTime? lastUpdateDate;

  const ValueSetValueModel({
    this.id,
    this.valueSetCode,
    this.code,
    this.name,
    this.parentCode,
    this.displayOrder,
    this.sortOrder,
    this.description,
    this.isActive,
    this.deleteFlg,
    this.effectiveFrom,
    this.effectiveTo,
    this.createdBy,
    this.updatedBy,
    this.creationDate,
    this.lastUpdateDate,
  });

  /// Convert từ JSON response (từ backend Go) sang Model
  factory ValueSetValueModel.fromJson(Map<String, dynamic> json) {
    return ValueSetValueModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
      valueSetCode: json['value_set_code']?.toString(),
      code: json['value_code']?.toString(),
      name: json['value_name']?.toString(),
      parentCode: json['parent_code']?.toString(),
      displayOrder: json['display_order'] is int ? json['display_order'] : int.tryParse(json['display_order']?.toString() ?? '0'),
      sortOrder: json['sort_order'] is int ? json['sort_order'] : int.tryParse(json['sort_order']?.toString() ?? '0'),
      description: json['description']?.toString(),
      isActive: _parseCharToBool(json['is_active']?.toString()),
      deleteFlg: _parseCharToBool(json['delete_flg']?.toString()),
      effectiveFrom: _parseDateTime(json['effective_from']),
      effectiveTo: _parseDateTime(json['effective_to']),
      createdBy: json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by']?.toString() ?? '0'),
      updatedBy: json['updated_by'] is int ? json['updated_by'] : int.tryParse(json['updated_by']?.toString() ?? '0'),
      creationDate: _parseDateTime(json['creation_date']),
      lastUpdateDate: _parseDateTime(json['last_update_date']),
    );
  }

  /// Convert Model sang JSON để gửi lên backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value_set_code': valueSetCode,
      'value_code': code,
      'value_name': name,
      'parent_code': parentCode,
      'display_order': displayOrder,
      'sort_order': sortOrder,
      'description': description,
      'is_active': isActive == true ? '1' : '0',
      'delete_flg': deleteFlg == true ? '1' : '0',
      'effective_from': effectiveFrom?.toIso8601String(),
      'effective_to': effectiveTo?.toIso8601String(),
    };
  }

  /// Helper: chuyển '0'/'1' hoặc 'true'/'false' thành bool
  static bool? _parseCharToBool(String? value) {
    if (value == null) return null;
    if (value == '1' || value.toLowerCase() == 'true') return true;
    if (value == '0' || value.toLowerCase() == 'false') return false;
    return null;
  }

  /// Helper: parse DateTime từ String ISO 8601
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// Kiểm tra xem giá trị có còn hiệu lực tại thời điểm hiện tại không
  /// Logic: isActive=true AND deleteFlg=false AND NOW() BETWEEN effective_from AND effective_to
  bool get isValidNow {
    final now = DateTime.now();
    if (isActive != true) return false;
    if (deleteFlg == true) return false;
    if (effectiveFrom != null && now.isBefore(effectiveFrom!)) return false;
    if (effectiveTo != null && now.isAfter(effectiveTo!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        valueSetCode,
        code,
        name,
        parentCode,
        displayOrder,
        sortOrder,
        description,
        isActive,
        deleteFlg,
        effectiveFrom,
        effectiveTo,
        createdBy,
        updatedBy,
        creationDate,
        lastUpdateDate,
      ];
}