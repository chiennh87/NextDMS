// OutletOnboardingBloc - Enterprise FMCG - Offline-First + Approval Workflow

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../core/storage/local_db.dart';
import '../../core/storage/sync_service.dart';
import '../models/outlet_dto.dart';
import '../models/value_set_model.dart';
import '../models/duplicate_check_model.dart';
import '../models/address_model.dart';
import '../repository/outlet_repository.dart';
import 'outlet_onboarding_event.dart';
import 'outlet_onboarding_state.dart';

/// OutletOnboardingBloc - toan bo business logic cho mo moi diem ban
class OutletOnboardingBloc
    extends Bloc<OutletOnboardingEvent, OutletOnboardingState> {
  final OutletRepository repository;
  final LocalDb? localDb;
  final SyncService? syncService;
  final _uuid = const Uuid();

  Timer? _duplicateCheckDebounce;

  OutletOnboardingBloc({
    required this.repository,
    this.localDb,
    this.syncService,
  }) : super(const OutletOnboardingInitial()) {
    on<OutletOnboardingInitialized>(_onInit);
    on<OutletFormUpdated>(_onFormUpdated);
    on<OutletProvinceSelected>(_onProvinceSelected);
    on<OutletDistrictSelected>(_onDistrictSelected);
    on<OutletWardSelected>(_onWardSelected);
    on<OutletCustomerTypeSelected>(_onCustomerTypeSelected);
    on<OutletCustomerChannelSelected>(_onCustomerChannelSelected);
    on<OutletTierSelected>(_onTierSelected);
    on<OutletGpsCaptureRequested>(_onGpsCapture);
    on<OutletPhotoUploaded>(_onPhotoUploaded);
    on<OutletDuplicateCheckRequested>(_onDuplicateCheck);
    on<_DuplicateCheckInternal>(_onDuplicateCheckInternal);
    on<OutletDuplicateCheckIgnored>(_onDuplicateIgnored);
    on<OutletOnboardingSubmitted>(_onSubmit);
    on<OutletDraftSavedLocally>(_onDraftSavedLocally);
    on<OutletSyncRequested>(_onSyncRequested);
    on<OutletSyncRetryRequested>(_onSyncRetryRequested);
    on<OutletDraftsRequested>(_onDraftsRequested);
  }

  Future<void> _onInit(OutletOnboardingInitialized event, Emitter<OutletOnboardingState> emit) async {
    emit(const OutletOnboardingLoading(message: 'Dang tai du lieu...'));
    try {
      final countries = await repository.getCountries();
      final bizTypes = await repository.getBusinessTypes();
      final customerTypes = await repository.getCustomerTypes();
      final channels = await repository.getChannels();
      final provinces = await repository.getProvincesByCountry('VNM');
      emit(OutletOnboardingReady(formData: OutletCreateRequestDTO.defaults(), countries: countries, businessTypes: bizTypes, customerTypes: customerTypes, channels: channels, provinces: provinces, selectedCountry: 'VNM', selectedBizType: 'HOP_KINH_DOANH'));
    } catch (e) { emit(OutletOnboardingError(message: 'Tai du lieu that bai: $e')); }
  }
  void _onFormUpdated(OutletFormUpdated event, Emitter<OutletOnboardingState> emit) { final s = state; if (s is OutletOnboardingReady) emit(s.copyWith(formData: event.formData)); }
  Future<void> _onProvinceSelected(OutletProvinceSelected event, Emitter<OutletOnboardingState> emit) async {
    final s = state; if (s is! OutletOnboardingReady) return;
    emit(s.copyWith(selectedProvince: event.provinceCode, selectedDistrict: null, selectedWard: null, districts: const [], wards: const []));
    try { final districts = await repository.getDistrictsByProvince(event.provinceCode); final st = state; if (st is OutletOnboardingReady) emit(st.copyWith(districts: districts)); } catch (e) {}


  // Offline Draft + Sync Handlers
  Future<void> _onDraftSavedLocally(OutletDraftSavedLocally event, Emitter<OutletOnboardingState> emit) async {
    if (localDb == null) { emit(OutletOnboardingFailure(message: 'Khong co localDb - khong the luu nhap')); return; }
    final localId = _uuid.v4();
    final draft = LocalOutletDraft(localId: localId, formDataJson: event.formData.toJson().toString(), createdAt: DateTime.now(), syncStatus: 'PENDING');
    try {
      await localDb!.saveDraft(draft);
      emit(OutletDraftSaved(localId: localId));
      final s = state;
      if (s is OutletOnboardingReady) emit(s);
    } catch (e) { emit(OutletOnboardingFailure(message: 'Luu nhap that bai: $e')); }
  }

  Future<void> _onSyncRequested(OutletSyncRequested event, Emitter<OutletOnboardingState> emit) async {
    if (localDb == null || syncService == null) { emit(OutletOnboardingFailure(message: 'Sync khong kha dung')); return; }
    try {
      final pending = await localDb!.getPendingDrafts();
      if (pending.isEmpty) { emit(OutletOnboardingSuccess(outletId: 0, outletCode: '', message: 'Khong co draft cho dong bo')); return; }
      emit(OutletSyncing(pendingCount: pending.length));
      int synced = 0; int failed = 0;
      for (final draft in pending) {
        try {
          final dto = _decodeDto(draft.formDataJson);
          if (dto == null) { await localDb!.updateSyncStatus(draft.localId, 'FAILED'); failed++; continue; }
          final result = await repository.syncOutlet(dto.copyWith(localId: draft.localId));
          if (result != null) { await localDb!.updateSyncStatus(draft.localId, 'SYNCED'); synced++; } else { await localDb!.updateSyncStatus(draft.localId, 'FAILED'); failed++; }
        } catch (e) { await localDb!.updateSyncStatus(draft.localId, 'FAILED'); failed++; }
      }
      emit(OutletSyncCompleted(syncedCount: synced, failedCount: failed));
    } catch (e) { emit(OutletOnboardingFailure(message: 'Dong bo that bai: $e')); }
  }

  Future<void> _onSyncRetryRequested(OutletSyncRetryRequested event, Emitter<OutletOnboardingState> emit) async {
    if (localDb == null) { emit(OutletOnboardingFailure(message: 'LocalDb khong kha dung')); return; }
    try {
      final failed = await localDb!.getPendingDrafts();
      if (failed.isEmpty) { emit(OutletOnboardingSuccess(outletId: 0, outletCode: '', message: 'Khong co draft loi')); return; }
      emit(OutletSyncing(pendingCount: failed.length));
      int synced = 0; int failedCount = 0;
      for (final draft in failed) {
        try {
          final dto = _decodeDto(draft.formDataJson);
          if (dto == null) { failedCount++; continue; }
          final result = await repository.syncOutlet(dto.copyWith(localId: draft.localId));
          if (result != null) { await localDb!.updateSyncStatus(draft.localId, 'SYNCED'); synced++; } else { failedCount++; }
        } catch (e) { failedCount++; }
      }
      emit(OutletSyncCompleted(syncedCount: synced, failedCount: failedCount));
    } catch (e) { emit(OutletOnboardingFailure(message: 'Retry that bai: $e')); }
  }

  Future<void> _onDraftsRequested(OutletDraftsRequested event, Emitter<OutletOnboardingState> emit) async {
    if (localDb == null) { emit(OutletDraftsLoaded(drafts: [])); return; }
    emit(const OutletDraftsLoading());
    try { final drafts = await localDb!.getPendingDrafts(); emit(OutletDraftsLoaded(drafts: drafts)); } catch (e) { emit(OutletDraftsLoaded(drafts: [])); }
  }

  // Helpers
  OutletCreateRequestDTO? _decodeDto(String json) { try { return OutletCreateRequestDTO.fromJson({}); } catch (e) { return null; } }

  @override
  Future<void> close() { _duplicateCheckDebounce?.cancel(); return super.close(); }
}

class _DuplicateCheckInternal extends OutletOnboardingEvent {
  final OutletCreateRequestDTO formData;
  const _DuplicateCheckInternal(this.formData);
}
  }
  Future<void> _onDistrictSelected(OutletDistrictSelected event, Emitter<OutletOnboardingState> emit) async {
    final s = state; if (s is! OutletOnboardingReady) return;
    emit(s.copyWith(selectedDistrict: event.districtCode, selectedWard: null, wards: const []));
    try { final wards = await repository.getWardsByDistrict(event.districtCode); final st = state; if (st is OutletOnboardingReady) emit(st.copyWith(wards: wards)); } catch (e) {}
  }
  void _onWardSelected(OutletWardSelected event, Emitter<OutletOnboardingState> emit) { final s = state; if (s is OutletOnboardingReady) emit(s.copyWith(selectedWard: event.wardCode)); }
  void _onCustomerTypeSelected(OutletCustomerTypeSelected event, Emitter<OutletOnboardingState> emit) { final s = state; if (s is OutletOnboardingReady) emit(s.copyWith(selectedCustomerType: event.customerTypeCode)); }
  void _onCustomerChannelSelected(OutletCustomerChannelSelected event, Emitter<OutletOnboardingState> emit) { final s = state; if (s is OutletOnboardingReady) emit(s.copyWith(selectedChannel: event.channelCode)); }
  void _onTierSelected(OutletTierSelected event, Emitter<OutletOnboardingState> emit) { final s = state; if (s is OutletOnboardingReady) emit(s.copyWith(selectedTier: event.tierCode)); }
  Future<void> _onGpsCapture(OutletGpsCaptureRequested event, Emitter<OutletOnboardingState> emit) async {
    final s = state; if (s is! OutletOnboardingReady) return;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) { final req = await Geolocator.requestPermission(); if (req == LocationPermission.denied || req == LocationPermission.deniedForever) { emit(OutletOnboardingError(message: 'Khong co quyen truy cap vi tri')); emit(s); return; } }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10));
      emit(s.copyWith(formData: s.formData.copyWith(latitude: pos.latitude, longitude: pos.longitude)));
    } catch (e) { emit(OutletOnboardingError(message: 'Khong lay duoc GPS: $e')); emit(s); }
  }
  void _onPhotoUploaded(OutletPhotoUploaded event, Emitter<OutletOnboardingState> emit) { final s = state; if (s is OutletOnboardingReady) emit(s.copyWith(formData: s.formData.copyWith(photoUrl: event.photoPath))); }
  Future<void> _onDuplicateCheck(OutletDuplicateCheckRequested event, Emitter<OutletOnboardingState> emit) async { _duplicateCheckDebounce?.cancel(); _duplicateCheckDebounce = Timer(const Duration(milliseconds: 300), () => add(_DuplicateCheckInternal(event.formData))); }
  Future<void> _onDuplicateCheckInternal(_DuplicateCheckInternal event, Emitter<OutletOnboardingState> emit) async {
    final s = state; if (s is! OutletOnboardingReady) return;
    emit(const OutletDuplicateChecking());
    try { final result = await repository.checkDuplicate(event.formData); final st = state; if (st is OutletOnboardingReady) { if (result.isDuplicate) { emit(OutletDuplicateFound(duplicateResult: result)); } else { emit(st); } } } catch (e) { final st = state; if (st is OutletOnboardingReady) emit(st); }
  }
  void _onDuplicateIgnored(OutletDuplicateCheckIgnored event, Emitter<OutletOnboardingState> emit) { final s = state; if (s is OutletOnboardingReady) emit(s.copyWith(duplicateIgnored: true)); }
  Future<void> _onSubmit(OutletOnboardingSubmitted event, Emitter<OutletOnboardingState> emit) async {
    final s = state; if (s is! OutletOnboardingReady) return;
    if (!s.duplicateIgnored) { emit(const OutletDuplicateChecking()); try { final dupResult = await repository.checkDuplicate(s.formData); if (dupResult.isDuplicate) { emit(OutletDuplicateFound(duplicateResult: dupResult)); return; } } catch (e) {} emit(s.copyWith(duplicateIgnored: true)); }
    emit(const OutletOnboardingSubmitting());
    try { final result = await repository.createOutlet(s.formData); emit(OutletOnboardingSuccess(outletId: result.id, outletCode: result.code, message: 'Tao diem ban thanh cong! Cho duyet.')); } catch (e) { emit(OutletOnboardingFailure(message: 'Tao diem ban that bai: $e')); }
  }