// Outlet Onboarding Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../models/outlet_dto.dart';
import '../models/value_set_model.dart';
import '../models/duplicate_check_model.dart';
import '../models/address_model.dart';
import '../repository/outlet_repository.dart';
import 'outlet_onboarding_event.dart';
import 'outlet_onboarding_state.dart';

class OutletOnboardingBloc extends Bloc<OutletOnboardingEvent, OutletOnboardingState> {
  final OutletRepository repository;
  OutletOnboardingBloc({required this.repository}) : super(const OutletOnboardingInitial()) {
    on<OutletOnboardingInitialized>(_onInit);
    on<OutletProvinceSelected>(_onProvinceSelected);
    on<OutletDistrictSelected>(_onDistrictSelected);
    on<OutletWardSelected>(_onWardSelected);
    on<OutletCustomerTypeSelected>(_onCustomerTypeSelected);
    on<OutletCustomerChannelSelected>(_onCustomerChannelSelected);
    on<OutletGpsCaptureRequested>(_onGpsCapture);
    on<OutletPhotoUploaded>(_onPhotoUploaded);
    on<OutletDuplicateCheckRequested>(_onDuplicateCheck);
    on<OutletDuplicateCheckIgnored>(_onDuplicateIgnored);
    on<OutletOnboardingSubmitted>(_onSubmit);
    on<OutletOnboardingReset>(_onReset);
  }

  Future<void> _onInit(OutletOnboardingInitialized event, Emitter<OutletOnboardingState> emit) async {
    emit(const OutletOnboardingLoading());
    try {
      final r = await Future.wait([repository.getProvinces(), repository.getValueSetValues('CUSTOMER_TYPE'), repository.getValueSetValues('CUSTOMER_CHANNEL')]);
      final ct = (r[1] as List<ValueSetValueModel>).where((v) => v.isValidNow).toList();
      final cc = (r[2] as List<ValueSetValueModel>).where((v) => v.isValidNow).toList();
      emit(OutletOnboardingReady(formData: const OutletCreateRequestDTO(), provinces: r[0] as List<AddressModel>, customerTypes: ct, customerChannels: cc));
    } catch (e) { emit(OutletOnboardingError('Lỗi tải: $e')); }
  }

  Future<void> _onProvinceSelected(OutletProvinceSelected event, Emitter<OutletOnboardingState> emit) async {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    emit(s.copyWith(formData: s.formData.copyWith(provinceCode: event.province.code, districtCode: null, wardCode: null), districts: const [], wards: const []));
    try {
      final d = await repository.getDistrictsByProvince(event.province.code!);
      if (state is OutletOnboardingReady) emit((state as OutletOnboardingReady).copyWith(districts: d));
    } catch (_) {}
  }

  Future<void> _onDistrictSelected(OutletDistrictSelected event, Emitter<OutletOnboardingState> emit) async {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    emit(s.copyWith(formData: s.formData.copyWith(districtCode: event.district.code, wardCode: null), wards: const []));
    try {
      final w = await repository.getWardsByDistrict(event.district.code!);
      if (state is OutletOnboardingReady) emit((state as OutletOnboardingReady).copyWith(wards: w));
    } catch (_) {}
  }

  void _onWardSelected(OutletWardSelected event, Emitter<OutletOnboardingState> emit) {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    emit(s.copyWith(formData: s.formData.copyWith(wardCode: event.ward.code)));
  }

  void _onCustomerTypeSelected(OutletCustomerTypeSelected event, Emitter<OutletOnboardingState> emit) {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    emit(s.copyWith(formData: s.formData.copyWith(customerTypeCode: event.customerType.code)));
  }

  void _onCustomerChannelSelected(OutletCustomerChannelSelected event, Emitter<OutletOnboardingState> emit) {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    emit(s.copyWith(formData: s.formData.copyWith(customerChannelCode: event.customerChannel.code)));
  }

  Future<void> _onGpsCapture(OutletGpsCaptureRequested event, Emitter<OutletOnboardingState> emit) async {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) { p = await Geolocator.requestPermission(); if (p == LocationPermission.denied) { emit(OutletOnboardingFailure(s.formData, 'Quyền vị trí bị từ chối')); emit(s); return; } }
      if (p == LocationPermission.deniedForever) { emit(OutletOnboardingFailure(s.formData, 'Bật quyền vị trí')); emit(s); return; }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      if (pos.accuracy > 20) { emit(OutletOnboardingFailure(s.formData, 'GPS: ${pos.accuracy.toStringAsFixed(1)}m')); emit(s); return; }
      emit(s.copyWith(formData: s.formData.copyWith(latitude: pos.latitude, longitude: pos.longitude), currentPosition: pos));
    } catch (e) { emit(OutletOnboardingFailure(s.formData, 'Lỗi GPS: $e')); emit(s); }
  }

  void _onPhotoUploaded(OutletPhotoUploaded event, Emitter<OutletOnboardingState> emit) {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    emit(s.copyWith(formData: s.formData.copyWith(photoUrl: event.photoUrl), photoUrl: event.photoUrl));
  }

  Future<void> _onDuplicateCheck(OutletDuplicateCheckRequested event, Emitter<OutletOnboardingState> emit) async {
    if (state is! OutletOnboardingReady) return;
    final s = state as OutletOnboardingReady;
    emit(OutletDuplicateChecking(event.formData));
    try {
      final r = await repository.checkDuplicate(phone: event.formData.phone, zaloPhone: event.formData.zaloPhone, taxCode: event.formData.taxCode, identityCardNumber: event.formData.identityCardNumber, latitude: event.formData.latitude, longitude: event.formData.longitude);
      if (r.hasDuplicate) emit(OutletDuplicateFound(event.formData, r));
      else add(OutletOnboardingSubmitted(event.formData));
    } catch (e) { emit(OutletOnboardingFailure(event.formData, 'Lỗi trùng: $e')); emit(s); }
  }

  void _onDuplicateIgnored(OutletDuplicateCheckIgnored event, Emitter<OutletOnboardingState> emit) {
    if (state is! OutletDuplicateFound) return;
    add(OutletOnboardingSubmitted((state as OutletDuplicateFound).formData));
  }

  Future<void> _onSubmit(OutletOnboardingSubmitted event, Emitter<OutletOnboardingState> emit) async {
    emit(OutletOnboardingSubmitting(event.formData));
    try {
      final err = _validate(event.formData);
      if (err != null) { emit(OutletOnboardingFailure(event.formData, err)); return; }
      final r = await repository.createOutlet(event.formData);
      emit(OutletOnboardingSuccess(r, 'Tạo thành công!'));
    } catch (e) { emit(OutletOnboardingFailure(event.formData, 'Lỗi: $e')); }
  }

  String? _validate(OutletCreateRequestDTO f) {
    if ((f.name ?? '').isEmpty) return 'Nhập tên điểm bán';
    if ((f.phone ?? '').isEmpty || !repository.isValidVietnamPhone(f.phone!)) return 'SĐT không hợp lệ';
    if ((f.zaloPhone ?? '').isNotEmpty && !repository.isValidZalo(f.zaloPhone!)) return 'Zalo không hợp lệ';
    if ((f.identityCardNumber ?? '').isNotEmpty && !repository.isValidIdCard(f.identityCardNumber!)) return 'CCCD 9/12 số';
    if ((f.taxCode ?? '').isNotEmpty && !repository.isValidTaxCode(f.taxCode!)) return 'MST 10/13 số';
    if (f.latitude == null || f.longitude == null) return 'Lấy GPS';
    if ((f.photoUrl ?? '').isEmpty) return 'Chụp ảnh mặt tiền';
    if ((f.provinceCode ?? '').isEmpty) return 'Chọn Tỉnh';
    if ((f.districtCode ?? '').isEmpty) return 'Chọn Quận';
    if ((f.wardCode ?? '').isEmpty) return 'Chọn Phường';
    return null;
  }

  void _onReset(OutletOnboardingReset event, Emitter<OutletOnboardingState> emit) => add(const OutletOnboardingInitialized());
}
