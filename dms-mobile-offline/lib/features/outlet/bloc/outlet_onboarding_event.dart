// ============================================================================
// Outlet Onboarding Bloc - Events
// ============================================================================

import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../models/outlet_dto.dart';
import '../models/value_set_model.dart';
import '../models/duplicate_check_model.dart';

/// Base event
abstract class OutletOnboardingEvent extends Equatable {
  const OutletOnboardingEvent();
  @override
  List<Object?> get props => [];
}

/// Khởi tạo màn hình (load master data + load GPS)
class OutletOnboardingInitialized extends OutletOnboardingEvent {
  const OutletOnboardingInitialized();
}

/// Cập nhật thông tin cơ bản của form (tên, tên chủ, ngày sinh, v.v.)
class OutletFormUpdated extends OutletOnboardingEvent {
  final OutletCreateRequestDTO formData;
  const OutletFormUpdated(this.formData);
  @override
  List<Object?> get props => [formData];
}

/// Cập nhật giá trị 1 trường đơn lẻ
class OutletFieldUpdated extends OutletOnboardingEvent {
  final String field;
  final dynamic value;
  const OutletFieldUpdated(this.field, this.value);
  @override
  List<Object?> get props => [field, value];
}

/// Thay đổi tỉnh/thành phố
class OutletProvinceSelected extends OutletOnboardingEvent {
  final AddressModel province;
  const OutletProvinceSelected(this.province);
  @override
  List<Object?> get props => [province];
}

/// Thay đổi quận/huyện
class OutletDistrictSelected extends OutletOnboardingEvent {
  final AddressModel district;
  const OutletDistrictSelected(this.district);
  @override
  List<Object?> get props => [district];
}

/// Thay đổi phường/xã
class OutletWardSelected extends OutletOnboardingEvent {
  final AddressModel ward;
  const OutletWardSelected(this.ward);
  @override
  List<Object?> get props => [ward];
}

/// Chọn Customer Type từ ValueSet
class OutletCustomerTypeSelected extends OutletOnboardingEvent {
  final ValueSetValueModel customerType;
  const OutletCustomerTypeSelected(this.customerType);
  @override
  List<Object?> get props => [customerType];
}

/// Chọn Customer Channel từ ValueSet
class OutletCustomerChannelSelected extends OutletOnboardingEvent {
  final ValueSetValueModel customerChannel;
  const OutletCustomerChannelSelected(this.customerChannel);
  @override
  List<Object?> get props => [customerChannel];
}

/// Bắt đầu lấy vị trí GPS
class OutletGpsCaptureRequested extends OutletOnboardingEvent {
  const OutletGpsCaptureRequested();
}

/// Nhận vị trí GPS từ Geolocator
class OutletGpsCaptured extends OutletOnboardingEvent {
  final Position position;
  const OutletGpsCaptured(this.position);
  @override
  List<Object?> get props => [position];
}

/// Upload ảnh mặt tiền thành công
class OutletPhotoUploaded extends OutletOnboardingEvent {
  final String photoUrl;
  const OutletPhotoUploaded(this.photoUrl);
  @override
  List<Object?> get props => [photoUrl];
}

/// Bắt đầu kiểm tra trùng lặp (debounce 500ms)
class OutletDuplicateCheckRequested extends OutletOnboardingEvent {
  final OutletCreateRequestDTO formData;
  const OutletDuplicateCheckRequested(this.formData);
  @override
  List<Object?> get props => [formData];
}

/// Bỏ qua cảnh báo trùng lặp và tiếp tục submit
class OutletDuplicateCheckIgnored extends OutletOnboardingEvent {
  const OutletDuplicateCheckIgnored();
}

/// Submit tạo điểm bán mới
class OutletOnboardingSubmitted extends OutletOnboardingEvent {
  final OutletCreateRequestDTO formData;
  const OutletOnboardingSubmitted(this.formData);
  @override
  List<Object?> get props => [formData];
}

/// Reset form về trạng thái ban đầu
class OutletOnboardingReset extends OutletOnboardingEvent {
  const OutletOnboardingReset();
}
/// Ch?n Tier (Ph�n h?ng di?m b�n - GOLD/SILVER/BRONZE)
class OutletTierSelected extends OutletOnboardingEvent {
  final ValueSetValueModel tier;
  const OutletTierSelected(this.tier);
  @override
  List<Object?> get props => [tier];
}

// Enterprise Sync Events (Offline-First)

class OutletDraftSavedLocally extends OutletOnboardingEvent {
  final OutletCreateRequestDTO formData;
  const OutletDraftSavedLocally(this.formData);
  @override
  List<Object?> get props => [formData];
}

class OutletSyncRequested extends OutletOnboardingEvent {
  const OutletSyncRequested();
}

class OutletSyncRetryRequested extends OutletOnboardingEvent {
  final String localId;
  const OutletSyncRetryRequested(this.localId);
  @override
  List<Object?> get props => [localId];
}

class OutletOnboardingReset extends OutletOnboardingEvent {
  const OutletOnboardingReset();
}
