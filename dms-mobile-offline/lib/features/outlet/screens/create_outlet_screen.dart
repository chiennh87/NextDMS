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
import '../repository/outlet_repository.dart';

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

  @override
  void dispose() {
    _nameCtrl.dispose(); _ownerCtrl.dispose(); _phoneCtrl.dispose();
    _zaloCtrl.dispose(); _idCardCtrl.dispose(); _taxCtrl.dispose();
    _licenseCtrl.dispose(); _streetCtrl.dispose(); _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) {
      setState(() => _photo = File(img.path));
      context.read<OutletOnboardingBloc>().add(OutletPhotoUploaded(img.path));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<OutletOnboardingBloc>().state;
    if (state is! OutletOnboardingReady) return;
    final dto = state.formData.copyWith(
      name: _nameCtrl.text, shortName: _ownerCtrl.text, phone: _phoneCtrl.text,
      zaloPhone: _zaloCtrl.text, identityCardNumber: _idCardCtrl.text,
      taxCode: _taxCtrl.text, businessLicenseNo: _licenseCtrl.text,
      businessType: _bizType, streetNumber: _streetCtrl.text,
      photoUrl: _photo?.path,
    );
    context.read<OutletOnboardingBloc>().add(OutletDuplicateCheckRequested(dto));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mở mới điểm bán')),
      body: BlocConsumer<OutletOnboardingBloc, OutletOnboardingState>(
        listener: (ctx, state) {
          if (state is OutletOnboardingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            Navigator.pop(context);
          } else if (state is OutletOnboardingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          } else if (state is OutletDuplicateFound) {
            _showDuplicateDialog(state.duplicateResult);
          }
        },
        builder: (ctx, state) {
          if (state is OutletOnboardingLoading || state is OutletOnboardingInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OutletOnboardingError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          if (state is OutletOnboardingSubmitting || state is OutletDuplicateChecking) {
            return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Đang xử lý...')]));
          }
          if (state is! OutletOnboardingReady) return const SizedBox();
          return _buildForm(state);
        },
      ),
    );
  }

  Widget _buildForm(OutletOnboardingReady state) {
    return Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      // Thông tin chung
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Thông tin chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên điểm bán *', prefixIcon: Icon(Icons.store)), validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _ownerCtrl, decoration: const InputDecoration(labelText: 'Tên chủ cửa hàng', prefixIcon: Icon(Icons.person)),
          validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _dobCtrl, decoration: const InputDecoration(labelText: 'Ngày sinh chủ cửa hàng', prefixIcon: Icon(Icons.calendar_today), hintText: 'YYYY-MM-DD'),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime(1990), firstDate: DateTime(1950), lastDate: DateTime.now());
            if (d != null) _dobCtrl.text = d.toIso8601String().split('T')[0];
          }),
        const SizedBox(height: 12),
        const Text('Loại hình kinh doanh:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'DOANH_NGHIEP', label: Text('Doanh nghiệp')), ButtonSegment(value: 'HOP_KINH_DOANH', label: Text('Hộ kinh doanh'))],
          selected: {_bizType}, onSelectionChanged: (s) => setState(() => _bizType = s.first)),
      ]))),
      const SizedBox(height: 16),
      // Thông tin liên hệ
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Thông tin liên hệ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'SĐT chính *', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _zaloCtrl, decoration: const InputDecoration(labelText: 'Số Zalo', prefixIcon: Icon(Icons.chat)), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 12),
        TextFormField(controller: _idCardCtrl, decoration: const InputDecoration(labelText: 'Số CCCD/CMND', prefixIcon: Icon(Icons.badge)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 12),
      ]))),
      const SizedBox(height: 16),
      // Thông tin pháp lý
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Thông tin pháp lý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextFormField(controller: _licenseCtrl, decoration: const InputDecoration(labelText: 'Số GPKD', prefixIcon: Icon(Icons.article))),
        const SizedBox(height: 12),
        TextFormField(controller: _taxCtrl, decoration: const InputDecoration(labelText: 'Mã số thuế', prefixIcon: Icon(Icons.receipt)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], maxLength: 13),
      ]))),
      const SizedBox(height: 16),
      // Địa chỉ
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Địa chỉ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownSearch<AddressModel>(
          items: (f, cs) => state.provinces.where((p) => p.name!.toLowerCase().contains(cs ?? '')).toList(),
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => m.name ?? '',
          selectedItem: state.provinces.where((p) => p.code == state.formData.provinceCode).firstOrNull,
          onChanged: (p) { if (p != null) context.read<OutletOnboardingBloc>().add(OutletProvinceSelected(p)); },
          decoratorBuilder: (ctx, ch) => InputDecoration(labelText: 'Tỉnh/Thành phố *', prefixIcon: const Icon(Icons.location_city), border: const OutlineInputBorder()),
          showSearchBox: true,
        ),
        const SizedBox(height: 12),
        DropdownSearch<AddressModel>(
          items: (f, cs) => state.districts.where((d) => d.name!.toLowerCase().contains(cs ?? '')).toList(),
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => m.name ?? '',
          selectedItem: state.districts.where((d) => d.code == state.formData.districtCode).firstOrNull,
          onChanged: (d) { if (d != null) context.read<OutletOnboardingBloc>().add(OutletDistrictSelected(d)); },
          decoratorBuilder: (ctx, ch) => InputDecoration(labelText: 'Quận/Huyện *', prefixIcon: const Icon(Icons.location_on), border: const OutlineInputBorder()),
          showSearchBox: true,
          enabled: state.districts.isNotEmpty,
        ),
        const SizedBox(height: 12),
        DropdownSearch<AddressModel>(
          items: (f, cs) => state.wards.where((w) => w.name!.toLowerCase().contains(cs ?? '')).toList(),
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => m.name ?? '',
          selectedItem: state.wards.where((w) => w.code == state.formData.wardCode).firstOrNull,
          onChanged: (w) { if (w != null) context.read<OutletOnboardingBloc>().add(OutletWardSelected(w)); },
          decoratorBuilder: (ctx, ch) => InputDecoration(labelText: 'Phường/Xã *', prefixIcon: const Icon(Icons.map), border: const OutlineInputBorder()),
          showSearchBox: true,
          enabled: state.wards.isNotEmpty,
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _streetCtrl, decoration: const InputDecoration(labelText: 'Số nhà/Tên đường', prefixIcon: Icon(Icons.home))),
      ]))),
      const SizedBox(height: 16),
      // Master data
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Phân loại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownSearch<ValueSetValueModel>(
          items: (f, cs) => state.customerTypes.where((t) => (t.name ?? '').toLowerCase().contains(cs ?? '')).toList(),
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => '${m.code} - ${m.name}',
          onChanged: (t) { if (t != null) context.read<OutletOnboardingBloc>().add(OutletCustomerTypeSelected(t)); },
          decoratorBuilder: (ctx, ch) => InputDecoration(labelText: 'Loại cửa hàng', prefixIcon: const Icon(Icons.category), border: const OutlineInputBorder()),
          showSearchBox: true,
        ),
        const SizedBox(height: 12),
        DropdownSearch<ValueSetValueModel>(
          items: (f, cs) => state.customerChannels.where((c) => (c.name ?? '').toLowerCase().contains(cs ?? '')).toList(),
          compareFn: (a, b) => a.code == b.code,
          itemAsString: (m) => '${m.code} - ${m.name}',
          onChanged: (c) { if (c != null) context.read<OutletOnboardingBloc>().add(OutletCustomerChannelSelected(c)); },
          decoratorBuilder: (ctx, ch) => InputDecoration(labelText: 'Kênh bán hàng', prefixIcon: const Icon(Icons.business), border: const OutlineInputBorder()),
          showSearchBox: true,
        ),
      ]))),
      const SizedBox(height: 16),
      // GPS & Photo
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Vị trí & Hình ảnh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (state.formData.latitude != null && state.formData.longitude != null)
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text('GPS: ${state.formData.latitude!.toStringAsFixed(6)}, ${state.formData.longitude!.toStringAsFixed(6)}'))]))
        else
          const Text('Chưa lấy GPS', style: TextStyle(color: Colors.orange)),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: () => context.read<OutletOnboardingBloc>().add(const OutletGpsCaptureRequested()), icon: const Icon(Icons.my_location), label: Text(state.formData.latitude != null ? 'Cập nhật GPS' : 'Lấy vị trí GPS')),
        const SizedBox(height: 16),
        const Text('Ảnh mặt tiền *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(onTap: _pickPhoto, child: _photo != null ? Image.file(_photo!, height: 200, fit: BoxFit.cover, borderRadius: BorderRadius.circular(8)) : Container(height: 150, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Nhấn để chụp ảnh')]))),
      ]))),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)), child: const Text('GỬI YÊU CẦU', style: TextStyle(fontSize: 16))),
      const SizedBox(height: 32),
    ]));
  }

  void _showDuplicateDialog(DuplicateCheckResult result) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text('Cảnh báo trùng lặp')]),
      content: SizedBox(width: double.maxFinite, child: ListView.builder(
        shrinkWrap: true, itemCount: result.matches.length,
        itemBuilder: (ctx, i) {
          final m = result.matches[i];
          return ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: Text(m.outletName ?? ''), subtitle: Text('${m.fieldDisplayName}: ${m.distance != null ? "${m.distance!.toStringAsFixed(0)}m" : "trùng"}'), trailing: m.distance != null ? Text('${m.distance!.toStringAsFixed(0)}m', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : null);
        },
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: () { Navigator.pop(context); context.read<OutletOnboardingBloc>().add(const OutletDuplicateCheckIgnored()); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Tiếp tục tạo'));
      ],
    ));
  }
}
