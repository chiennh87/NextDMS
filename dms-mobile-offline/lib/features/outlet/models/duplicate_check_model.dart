// ============================================================================
// Duplicate Check Model (Kết quả kiểm tra trùng lặp điểm bán)
// ============================================================================

import 'package:equatable/equatable.dart';

/// Kết quả kiểm tra trùng lặp (Duplicate Detection Result)
class DuplicateCheckResult extends Equatable {
  final List<DuplicateMatch> matches;
  final bool hasDuplicate;

  const DuplicateCheckResult({
    this.matches = const [],
    this.hasDuplicate = false,
  });

  factory DuplicateCheckResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> matchesList = json['matches'] ?? json['data'] ?? [];
    return DuplicateCheckResult(
      matches: matchesList
          .map((e) => DuplicateMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasDuplicate: matchesList.isNotEmpty,
    );
  }

  @override
  List<Object?> get props => [matches, hasDuplicate];
}

/// Thông tin match khi phát hiện trùng lặp
class DuplicateMatch extends Equatable {
  final int? outletId;
  final String? outletCode;
  final String? outletName;
  final String? fieldName;       // 'phone', 'zalo', 'tax_code', 'identity_card', 'gps'
  final String? matchType;       // 'exact' hoặc 'distance'
  final double? distance;        // Khoảng cách (mét) - chỉ có với fieldName='gps'
  final String? address;
  final double? latitude;
  final double? longitude;

  const DuplicateMatch({
    this.outletId,
    this.outletCode,
    this.outletName,
    this.fieldName,
    this.matchType,
    this.distance,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory DuplicateMatch.fromJson(Map<String, dynamic> json) {
    return DuplicateMatch(
      outletId: json['outlet_id'] is int ? json['outlet_id'] : int.tryParse(json['outlet_id']?.toString() ?? '0'),
      outletCode: json['outlet_code']?.toString(),
      outletName: json['outlet_name']?.toString(),
      fieldName: json['field_name']?.toString(),
      matchType: json['match_type']?.toString(),
      distance: json['distance'] is num ? (json['distance'] as num).toDouble() : null,
      address: json['address']?.toString(),
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
    );
  }

  /// Lấy tên tiếng Việt của field
  String get fieldDisplayName {
    switch (fieldName) {
      case 'phone':
        return 'Số điện thoại';
      case 'zalo':
        return 'Số Zalo';
      case 'tax_code':
        return 'Mã số thuế';
      case 'identity_card':
        return 'Số CCCD/CMND';
      case 'gps':
        return 'Vị trí GPS';
      default:
        return fieldName ?? 'Không rõ';
    }
  }

  @override
  List<Object?> get props => [
        outletId,
        outletCode,
        outletName,
        fieldName,
        matchType,
        distance,
        address,
        latitude,
        longitude,
      ];
}