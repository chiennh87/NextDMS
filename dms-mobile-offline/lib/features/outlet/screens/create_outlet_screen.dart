// ============================================================================
// Create Outlet Screen - Mo moi Diem ban (Outlet Onboarding)
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../bloc/outlet_onboarding_bloc.dart';
import '../bloc/outlet_onboarding_event.dart';
import '../bloc/outlet_onboarding_state.dart';
import '../models/outlet_dto.dart';
import '../models/value_set_model.dart';
import '../models/duplicate_check_model.dart';
import '../models/address_model.dart';
import '../widgets/sync_status_banner.dart';
import '../models/address_model.dart';

class CreateOutletScreen extends StatefulWidget {
  const CreateOutletScreen({super.key});
  @override
  State<CreateOutletScreen> createState() => _CreateOutletScreenState();
}

class _CreateOutletScreenState extends State<CreateOutletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _zaloCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  File? _photo;
  String _bizType = 'HOP_KINH_DOANH';
  DateTime? _ownerDob;
  int _debounceKey = 0;  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_onFieldChanged);
    _zaloCtrl.addListener(_onFieldChanged);
    _idCardCtrl.addListener(_onFieldChanged);
    _taxCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final bloc = context.read<OutletOnboardingBloc>();
    if (bloc.state is! OutletOnboardingReady) return;
    final s = bloc.state as OutletOnboardingReady;
    _debounceKey++;
    final key = _debounceKey;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (key != _debounceKey) return;
      _triggerDuplicateCheck(s);
    });
  }

  void _triggerDuplicateCheck(OutletOnboardingReady s) {
    final dto = _buildCurrentDto(s);
    if ((dto.phone ?? "").isEmpty &&
        (dto.zaloPhone ?? "").isEmpty &&
        (dto.identityCardNumber ?? "").isEmpty &&
        (dto.taxCode ?? "").isEmpty &&
        dto.latitude == null) return;
    context.read<OutletOnboardingBloc>().add(OutletDuplicateCheckRequested(dto));
  }

  OutletCreateRequestDTO _buildCurrentDto(OutletOnboardingReady s) {
    return s.formData.copyWith(
      name: _nameCtrl.text,
      shortName: _ownerCtrl.text,
      ownerDob: _ownerDob,
      phone: _phoneCtrl.text,
      zaloPhone: _zaloCtrl.text,
      identityCardNumber: _idCardCtrl.text,
      taxCode: _taxCtrl.text,
      businessLicenseNo: _licenseCtrl.text,
      businessType: _bizType,
      streetNumber: _streetCtrl.text,
      photoUrl: _photo?.path,
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (img != null) {
      setState(() => _photo = File(img.path));
      context.read<OutletOnboardingBloc>().add(OutletPhotoUploaded(img.path));
    }
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _ownerDob ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18),
      locale: const Locale("vi", "VN"),
    );
    if (picked != null) {
      setState(() {
        _ownerDob = picked;
        _dobCtrl.text = "${picked.day.toString().padLeft(2, "0")}/"
            "${picked.month.toString().padLeft(2, "0")}/${picked.year}";
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<OutletOnboardingBloc>().state;
    if (state is! OutletOnboardingReady) return;
    final dto = _buildCurrentDto(state);
    context.read<OutletOnboardingBloc>().add(OutletDuplicateCheckRequested(dto));
  }

  void _saveDraft() {
    final state = context.read<OutletOnboardingBloc>().state;
    if (state is! OutletOnboardingReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long cho form load xong')),
      );
      return;
    }
    final dto = _buildCurrentDto(state);
    context.read<OutletOnboardingBloc>().add(OutletDraftSavedLocally(dto));
  }
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<OutletOnboardingBloc>().state;
    if (state is! OutletOnboardingReady) return;
    final dto = _buildCurrentDto(state);
    context.read<OutletOnboardingBloc>().add(OutletDuplicateCheckRequested(dto));
  }

  @override
  void dispose() {
    _debounceKey++;
    _nameCtrl.dispose(); _ownerCtrl.dispose(); _phoneCtrl.dispose();
    _zaloCtrl.dispose(); _idCardCtrl.dispose(); _taxCtrl.dispose();
    _licenseCtrl.dispose(); _streetCtrl.dispose(); _dobCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mo moi diem ban"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OutletOnboardingBloc>().add(const OutletOnboardingReset()),
          ),
        ],
      body: BlocConsumer<OutletOnboardingBloc, OutletOnboardingState>(
        listener: (ctx, state) {
          if (state is OutletOnboardingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is OutletOnboardingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is OutletDuplicateFound) {
            _showDuplicateDialog(state.duplicateResult);
          } else if (state is OutletDraftSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Da luu nhap thanh cong (${state.localId.substring(0, 8)}...)'),
                backgroundColor: Colors.blue,
                action: SnackBarAction(
                  label: 'Dong bo',
                  textColor: Colors.white,
                  onPressed: () => context.read<OutletOnboardingBloc>().add(const OutletSyncRequested()),
                ),
              ),
            );
          } else if (state is OutletSyncCompleted) {
            final allSuccess = state.failedCount == 0;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(allSuccess
                    ? 'Dong bo thanh cong ${state.syncedCount} muc!'
                    : 'Dong bo: ${state.syncedCount} thanh cong, ${state.failedCount} that bai'),
                backgroundColor: allSuccess ? Colors.green : Colors.orange,
              ),
            );
          }
        },
      ),
      body: BlocConsumer<OutletOnboardingBloc, OutletOnboardingState>(
        listener: (ctx, state) {
          if (state is OutletOnboardingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is OutletOnboardingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is OutletDuplicateFound) {
            _showDuplicateDialog(state.duplicateResult);
          }
        },
        builder: (ctx, state) {
          if (state is OutletOnboardingLoading || state is OutletOnboardingInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OutletOnboardingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<OutletOnboardingBloc>().add(const OutletOnboardingInitialized()),
                    child: const Text("Thu lai"),
                  ),
                ],
              ),
            );
          }
          if (state is OutletDuplicateChecking || state is OutletOnboardingSubmitting) {
            return Stack(
              children: [
                _buildForm(state is OutletOnboardingReady ? state : null),
                Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
              ],
            );
          }
          if (state is OutletOnboardingReady) {
            return _buildForm(state);
          }
          // Handle sync states with banner
          return _buildForm(null);
        },
      ),
    );
  }
          if (state is OutletOnboardingReady) {
            return _buildForm(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
  Widget _buildForm(OutletOnboardingReady? s) {
    if (s == null) return const SizedBox.shrink();
    return Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sync status banner
          SyncStatusBanner(
            state: context.watch<OutletOnboardingBloc>().state,
            onSyncTap: () => context.read<OutletOnboardingBloc>().add(const OutletSyncRequested()),
            onRetryTap: () => context.read<OutletOnboardingBloc>().add(const OutletSyncRetryRequested()),
          ),
          const SizedBox(height: 8),
          _buildGeneralSection(s),
          const SizedBox(height: 16),
          _buildContactSection(s),
          const SizedBox(height: 16),
          _buildLegalSection(s),
          const SizedBox(height: 16),
          _buildAddressSection(s),
          const SizedBox(height: 16),
          _buildMasterDataSection(s),
          const SizedBox(height: 16),
          _buildGpsPhotoSection(s),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text("Luu nhap"),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text("GUI YEU CAU", style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
              ),
            ],
          ),
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGeneralSection(s),
          const SizedBox(height: 16),
          _buildContactSection(s),
          const SizedBox(height: 16),
          _buildLegalSection(s),
          const SizedBox(height: 16),
          _buildAddressSection(s),
          const SizedBox(height: 16),
          _buildMasterDataSection(s),
          const SizedBox(height: 16),
          _buildGpsPhotoSection(s),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.send),
            label: const Text("GUI YEU CAU", style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  Widget _buildSectionCard(String title, Widget child) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
  Widget _buildGeneralSection(OutletOnboardingReady s) {
    return _buildSectionCard("Thong tin chung", Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: "Ten diem ban *",
            prefixIcon: Icon(Icons.store),
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v ?? "").trim().isEmpty ? "Vui long nhap ten diem ban" : null,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ownerCtrl,
          decoration: const InputDecoration(
            labelText: "Ten chu cua hang",
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dobCtrl,
          readOnly: true,
          onTap: _selectDob,
          decoration: const InputDecoration(
            labelText: "Ngay sinh chu cua hang",
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    ));
  }
  Widget _buildContactSection(OutletOnboardingReady s) {
    return _buildSectionCard("Thong tin lien he & Dinh danh", Column(
      children: [
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(
            labelText: "So dien thoai *",
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            hintText: "VD: 0912345678",
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if ((v ?? "").isEmpty) return "Vui long nhap so dien thoai";
            if (!RegExp(r"^(?:\+84|0)[35789]\d{8}$").hasMatch(v!.replaceAll(" ", ""))) {
              return "So dien thoai khong dung dinh dang";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _zaloCtrl,
          decoration: const InputDecoration(
            labelText: "So Zalo",
            prefixIcon: Icon(Icons.chat),
            border: OutlineInputBorder(),
            hintText: "VD: 0912345678",
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _idCardCtrl,
          decoration: const InputDecoration(
            labelText: "So CCCD/CMND",
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
            hintText: "9 hoac 12 chu so",
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    ));
  }
  Widget _buildLegalSection(OutletOnboardingReady s) {
    return _buildSectionCard("Thong tin phap ly", Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Loai hinh kinh doanh *", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: "DOANH_NGHIEP", label: Text("Doanh nghiep"), icon: Icon(Icons.business)),
            ButtonSegment(value: "HOP_KINH_DOANH", label: Text("Ho kinh doanh"), icon: Icon(Icons.storefront)),
          ],
          selected: {_bizType},
          onSelectionChanged: (v) => setState(() => _bizType = v.first),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _licenseCtrl,
          decoration: const InputDecoration(
            labelText: "So GPKD",
            prefixIcon: Icon(Icons.assignment),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _taxCtrl,
          decoration: const InputDecoration(
            labelText: "Ma so thue",
            prefixIcon: Icon(Icons.account_balance),
            border: OutlineInputBorder(),
            hintText: "10 hoac 13 chu so",
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    ));
  }
  Widget _buildAddressSection(OutletOnboardingReady s) {
    return _buildSectionCard("Dia chi", Column(
      children: [
        DropdownSearch<AddressModel>(
          items: (filter, loadProps) => s.provinces,
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => "${m.code} - ${m.name}",
          selectedItem: s.provinces.where((p) => p.code == s.formData.provinceCode).firstOrNull,
          onChanged: (p) {
            if (p != null) _onProvinceSelected(s, p);
          },
          decoratorBuilder: (ctx, child) => InputDecoration(
            labelText: "Tinh/Thanh pho *",
            prefixIcon: const Icon(Icons.location_city),
            border: const OutlineInputBorder(),
          ),
          showSearchBox: true,
          searchBoxDecoration: const InputDecoration(hintText: "Tim tinh/thanh pho..."),
        ),
        const SizedBox(height: 12),
        DropdownSearch<AddressModel>(
          items: (filter, loadProps) => s.districts,
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => "${m.code} - ${m.name}",
          selectedItem: s.districts.where((d) => d.code == s.formData.districtCode).firstOrNull,
          onChanged: (d) => _onDistrictSelected(s, d),
          enabled: s.districts.isNotEmpty,
          decoratorBuilder: (ctx, child) => InputDecoration(
            labelText: "Quan/Huyen *",
            prefixIcon: const Icon(Icons.location_on),
            border: const OutlineInputBorder(),
          ),
          showSearchBox: true,
          searchBoxDecoration: const InputDecoration(hintText: "Tim quan/huyen..."),
        ),
        const SizedBox(height: 12),
        DropdownSearch<AddressModel>(
          items: (filter, loadProps) => s.wards,
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => "${m.code} - ${m.name}",
          selectedItem: s.wards.where((w) => w.code == s.formData.wardCode).firstOrNull,
          onChanged: _onWardSelected,
          enabled: s.wards.isNotEmpty,
          decoratorBuilder: (ctx, child) => InputDecoration(
            labelText: "Phuong/Xa *",
            prefixIcon: const Icon(Icons.map),
            border: const OutlineInputBorder(),
          ),
          showSearchBox: true,
          searchBoxDecoration: const InputDecoration(hintText: "Tim phuong/xa..."),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _streetCtrl,
          decoration: const InputDecoration(
            labelText: "So nha / Ten duong",
            prefixIcon: Icon(Icons.home),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ));
  }
  Widget _buildMasterDataSection(OutletOnboardingReady s) {
    return _buildSectionCard("Phan hang & Phan loai", Column(
      children: [
        DropdownSearch<ValueSetValueModel>(
          items: (filter, loadProps) => s.customerTypes,
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => "${m.code} - ${m.name}",
          selectedItem: s.customerTypes.where((v) => v.code == s.formData.customerTypeCode).firstOrNull,
          onChanged: _onCustomerTypeSelected,
          decoratorBuilder: (ctx, child) => InputDecoration(
            labelText: "Loai cua hang (CUSTOMER_TYPE)",
            prefixIcon: const Icon(Icons.category),
            border: const OutlineInputBorder(),
          ),
          showSearchBox: true,
        ),
        const SizedBox(height: 12),
        DropdownSearch<ValueSetValueModel>(
          items: (filter, loadProps) => s.customerChannels,
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => "${m.code} - ${m.name}",
          selectedItem: s.customerChannels.where((v) => v.code == s.formData.customerChannelCode).firstOrNull,
          onChanged: _onCustomerChannelSelected,
          decoratorBuilder: (ctx, child) => InputDecoration(
            labelText: "Kenh ban hang (CUSTOMER_CHANNEL)",
            prefixIcon: const Icon(Icons.business),
            border: const OutlineInputBorder(),
          ),
          showSearchBox: true,
        ),
        const SizedBox(height: 12),
        DropdownSearch<ValueSetValueModel>(
          items: (filter, loadProps) => s.tiers,
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => "${m.code} - ${m.name}",
          selectedItem: s.tiers.where((v) => v.code == s.formData.tier).firstOrNull,
          onChanged: _onTierSelected,
          decoratorBuilder: (ctx, child) => InputDecoration(
            labelText: "Phan hang diem ban",
            prefixIcon: const Icon(Icons.star),
            border: const OutlineInputBorder(),
          ),
          showSearchBox: true,
        ),
      ],
    ));
  }
  Widget _buildGpsPhotoSection(OutletOnboardingReady s) {
    return _buildSectionCard("Vi tri & Hinh anh", Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.formData.latitude != null && s.formData.longitude != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text("GPS: ${s.formData.latitude!.toStringAsFixed(6)}, ${s.formData.longitude!.toStringAsFixed(6)}")),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text("Chua lay GPS - can cho viec canh bao vi tri")]),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => context.read<OutletOnboardingBloc>().add(const OutletGpsCaptureRequested()),
          icon: const Icon(Icons.my_location),
          label: Text(s.formData.latitude != null ? "Cap nhat GPS" : "Lay vi tri GPS"),
        ),
        const SizedBox(height: 16),
        const Text("Anh mat tien *", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickPhoto,
          child: _photo != null
              ? Image.file(_photo!, height: 200, fit: BoxFit.cover, width: double.infinity)
              : Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 48, color: Colors.grey), SizedBox(height: 8), Text("Nhan de chup anh")]),
                ),
        ),
      ],
    ));
  }

  void _showDuplicateDialog(DuplicateCheckResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text("Canh bao trung lap")]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Phat hien diem ban trung voi:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...result.matches.map((m) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(m.outletName ?? ""),
                subtitle: Text("${m.fieldDisplayName}: ${m.distance != null ? "${m.distance!.toStringAsFixed(0)}m" : "trung"}"),
                trailing: m.distance != null ? Text("${m.distance!.toStringAsFixed(0)}m", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : null,
              ),
            )),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Huy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OutletOnboardingBloc>().add(const OutletDuplicateCheckIgnored());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Tiep tuc tao"),
          ),
        ],
      ),
    );
  }
}
