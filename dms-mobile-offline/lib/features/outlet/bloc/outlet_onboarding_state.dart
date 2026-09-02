// ============================================================================
// Outlet Onboarding Bloc - States
// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../models/outlet_dto.dart';
import '../models/value_set_model.dart';
import '../models/duplicate_check_model.dart';
import '../models/address_model.dart';

/// Base state
abstract class OutletOnboardingState extends Equatable {
  const OutletOnboardingState();
  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu (chưa khởi tạo)
class OutletOnboardingInitial extends OutletOnboardingState {
  const OutletOnboardingInitial();
}

/// Đang tải master data (provinces, customer types, channels, tiers)
class OutletOnboardingLoading extends OutletOnboardingState {
  const OutletOnboardingLoading();
}

/// Đã load xong master data, sẵn sàng nhập liệu
class OutletOnboardingReady extends OutletOnboardingState {
  final OutletCreateRequestDTO formData;
  final List<AddressModel> provinces;
  final List<ValueSetValueModel> customerTypes;
  final List<ValueSetValueModel> customerChannels;
  final List<ValueSetValueModel> tiers;
  final List<AddressModel> districts;
  final List<AddressModel> wards;
  final Position? currentPosition;
  final String? photoUrl;

  const OutletOnboardingReady({
    required this.formData,
    required this.provinces,
    required this.customerTypes,
    required this.customerChannels,
    this.tiers = const [],
    this.districts = const [],
    this.wards = const [],
    this.currentPosition,
    this.photoUrl,
  });

  OutletOnboardingReady copyWith({
    OutletCreateRequestDTO? formData,
    List<AddressModel>? provinces,
    List<ValueSetValueModel>? customerTypes,
    List<ValueSetValueModel>? customerChannels,
    List<ValueSetValueModel>? tiers,
    List<AddressModel>? districts,
    List<AddressModel>? wards,
    Position? currentPosition,
    String? photoUrl,
  }) {
    return OutletOnboardingReady(
      formData: formData ?? this.formData,
      provinces: provinces ?? this.provinces,
      customerTypes: customerTypes ?? this.customerTypes,
      customerChannels: customerChannels ?? this.customerChannels,
      tiers: tiers ?? this.tiers,
      districts: districts ?? this.districts,
      wards: wards ?? this.wards,
      currentPosition: currentPosition ?? this.currentPosition,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [
    formData, provinces, customerTypes, customerChannels, tiers,
    districts, wards, currentPosition, photoUrl,
  ];
}

/// Đang kiểm tra trùng lặp (debounced)
class OutletDuplicateChecking extends OutletOnboardingState {
  final OutletCreateRequestDTO formData;
  const OutletDuplicateChecking(this.formData);
  @override
  List<Object?> get props => [formData];
}

/// Tìm thấy trùng lặp - hiển thị dialog cảnh báo
class OutletDuplicateFound extends OutletOnboardingState {
  final OutletCreateRequestDTO formData;
  final DuplicateCheckResult duplicateResult;
  const OutletDuplicateFound(this.formData, this.duplicateResult);
  @override
  List<Object?> get props => [formData, duplicateResult];
}

/// Đang submit tạo outlet
class OutletOnboardingSubmitting extends OutletOnboardingState {
  final OutletCreateRequestDTO formData;
  const OutletOnboardingSubmitting(this.formData);
  @override
  List<Object?> get props => [formData];
}

/// Tạo outlet thành công
class OutletOnboardingSuccess extends OutletOnboardingState {
  final OutletCreateRequestDTO createdOutlet;
  final String message;
  const OutletOnboardingSuccess(this.createdOutlet, this.message);
  @override
  List<Object?> get props => [createdOutlet, message];
}

/// Lỗi (validation, network, server)
class OutletOnboardingFailure extends OutletOnboardingState {
  final OutletCreateRequestDTO formData;
  final String message;
  const OutletOnboardingFailure(this.formData, this.message);
  @override
  List<Object?> get props => [formData, message];
}

/// Lỗi load master data
class OutletOnboardingError extends OutletOnboardingState {
  final String message;
  const OutletOnboardingError(this.message);
  @override
  List<Object?> get props => [message];
}
// Enterprise: Sync States (Offline-First)

class OutletDraftSaved extends OutletOnboardingState {
  final OutletCreateRequestDTO formData;
  final String localId;
  final String message;
  const OutletDraftSaved(this.formData, this.localId, this.message);
  @override
  List<Object?> get props => [formData, localId, message];
}

class OutletSyncing extends OutletOnboardingState {
  final int pendingCount;
  final int syncedCount;
  final int failedCount;
  const OutletSyncing({this.pendingCount = 0, this.syncedCount = 0, this.failedCount = 0});
  @override
  List<Object?> get props => [pendingCount, syncedCount, failedCount];
}

class OutletSyncCompleted extends OutletOnboardingState {
  final int syncedCount;
  final int failedCount;
  final String? lastError;
  const OutletSyncCompleted({required this.syncedCount, required this.failedCount, this.lastError});
  @override
  List<Object?> get props => [syncedCount, failedCount, lastError];
}
