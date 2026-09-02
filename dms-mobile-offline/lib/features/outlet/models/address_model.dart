// ============================================================================
// Address Model - Province/District/Ward
// ============================================================================

import 'package:equatable/equatable.dart';

/// Model cho địa chỉ (Tỉnh/Thành phố, Quận/Huyện, Phường/Xã)
class AddressModel extends Equatable {
  final int? id;
  final String? code;
  final String? name;
  final String? parentCode;
  final String? streetNumber;
  final String? streetName;

  const AddressModel({
    this.id,
    this.code,
    this.name,
    this.parentCode,
    this.streetNumber,
    this.streetName,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
      code: json['province_code']?.toString() ??
            json['district_code']?.toString() ??
            json['ward_code']?.toString(),
      name: json['province_name']?.toString() ??
            json['district_name']?.toString() ??
            json['ward_name']?.toString(),
      parentCode: json['province_code']?.toString() ??
                  json['district_code']?.toString(),
      streetNumber: json['street_number']?.toString(),
      streetName: json['street_name']?.toString(),
    );
  }

  @override
  String toString() => name ?? '';

  @override
  List<Object?> get props => [id, code, name, parentCode, streetNumber, streetName];
}