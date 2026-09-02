// Forgot Password Screen with 3 steps: Email, OTP, New Password
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/forgot_password_bloc.dart';
import '../models/forgot_password_models.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  String? _email;
  String _otp = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordBloc(),
      child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (ctx, state) {
          if (state is OTPRequested && _step == 0) setState(() => _step = 1);
          if (state is ForgotPasswordError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
          if (state is PasswordReset) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quen Mat Khau'), backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [_stepIndicator(), const SizedBox(height: 32), if (state is ForgotPasswordLoading) const Center(child: CircularProgressIndicator()) else _buildStep(ctx, state)]),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _stepIndicator() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [_dot(0, 'Email'), _line(0), _dot(1, 'OTP'), _line(1), _dot(2, 'MK')]);

  Widget _dot(int s, String label) {
    final active = _step >= s;
    return Column(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: active ? const Color(0xFF1976D2) : Colors.grey[300], shape: BoxShape.circle), child: Center(child: Text('${s + 1}', style: TextStyle(color: active ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold)))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: active ? const Color(0xFF1976D2) : Colors.grey)),
    ]);
  }

  Widget _line(int after) => Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20), color: _step > after ? const Color(0xFF1976D2) : Colors.grey[300]));

  Widget _buildStep(BuildContext ctx, ForgotPasswordState state) {
    if (_step == 0) return _emailStep(ctx);
    if (_step == 1) return _otpStep(ctx, state);
    return _pwStep(ctx);
  }


  Widget _emailStep(BuildContext ctx) => Column(children: [
    const Icon(Icons.lock_outline, size: 64, color: Color(0xFF1976D2)),
    const SizedBox(height: 16),
    const Text('Nhap email dang ky', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text('Chung toi se gui ma xac nhan den email', style: TextStyle(color: Colors.grey[600])),
    const SizedBox(height: 32),
    TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: () { if (_emailCtrl.text.contains('@')) { ctx.read<ForgotPasswordBloc>().add(RequestOTPEvent(_emailCtrl.text)); _email = _emailCtrl.text; } }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Gui Ma OTP')),
    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Quay lai dang nhap')),
  ]);


  Widget _otpStep(BuildContext ctx, ForgotPasswordState state) {
    final countdown = state is OTPRequested ? state.countdownSeconds : 0;
    final canResend = countdown <= 0;
    return Column(children: [
      const Icon(Icons.sms, size: 64, color: Color(0xFF1976D2)),
      const SizedBox(height: 16),
      const Text('Nhap ma xac nhan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Ma OTP da gui den ' + (_email ?? ''), style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      TextField(controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 8), inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintText: '------'), onChanged: (v) { if (v.length == 6) { setState(() { _otp = v; _step = 2; }); } }),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Gui lai sau ', style: TextStyle(color: Colors.grey[600])), Text(canResend ? 'Gui lai' : '$countdown s', style: TextStyle(color: canResend ? const Color(0xFF1976D2) : Colors.grey, fontWeight: FontWeight.bold))]),
      if (canResend) TextButton(onPressed: () => ctx.read<ForgotPasswordBloc>().add(ResendOTPEvent(_email!)), child: const Text('Gui lai OTP')),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _otp.length == 6 ? () => setState(() => _step = 2) : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Xac Nhan')),
      TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Nhap lai email')),
    ]);
  }


  Widget _pwStep(BuildContext ctx) {
    final s = _checkStrength(_newPassword);
    return Column(children: [
      const Icon(Icons.password, size: 64, color: Color(0xFF1976D2)),
      const SizedBox(height: 16),
      const Text('Dat mat khau moi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      TextField(controller: _pwCtrl, obscureText: _obscurePw, onChanged: (v) => setState(() => _newPassword = v), decoration: InputDecoration(labelText: 'Mat khau moi', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_obscurePw ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePw = !_obscurePw)))),
      if (_newPassword.isNotEmpty) ...[const SizedBox(height: 8), _strengthBar(s), ...s.issues.map((i) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [const Icon(Icons.warning_amber, size: 14, color: Colors.orange), const SizedBox(width: 4), Text(i, style: const TextStyle(fontSize: 12, color: Colors.orange))])))],
      const SizedBox(height: 16),
      TextField(controller: _confirmCtrl, obscureText: _obscureConfirm, onChanged: (v) => setState(() => _confirmPassword = v), decoration: InputDecoration(labelText: 'Xac nhan mat khau', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)))),
      if (_confirmPassword.isNotEmpty && _newPassword != _confirmPassword) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Mat khau khong khop', style: TextStyle(color: Colors.red, fontSize: 12))),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _canSubmit() ? () => ctx.read<ForgotPasswordBloc>().add(ResetPasswordEvent(_email!, _otp, _newPassword)) : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Dat Lai Mat Khau')),
      TextButton(onPressed: () => setState(() => _step = 1), child: const Text('Nhap lai OTP')),
    ]);
  }


  Widget _strengthBar(PasswordStrength s) {
    final colors = [Colors.red, Colors.orange, Colors.yellow[700]!, Colors.lightGreen, Colors.green];
    final labels = ['Yeu', 'Trung binh', 'Kha', 'Manh'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(4, (i) => Expanded(child: Container(height: 4, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: i < s.score ? colors[s.score.clamp(0, 4)] : Colors.grey[300], borderRadius: BorderRadius.circular(2)))))),
      const SizedBox(height: 4),
      Text('Do manh: ' + labels[s.score.clamp(0, 3)], style: TextStyle(fontSize: 12, color: colors[s.score.clamp(0, 4)])),
    ]);
  }

  PasswordStrength _checkStrength(String pw) {
    if (pw.isEmpty) return PasswordStrength.empty;
    int score = 0; List<String> issues = [];
    if (pw.length >= 8) score++;
    if (pw.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (pw.length < 8) issues.add('It nhat 8 ky tu');
    if (!RegExp(r'[A-Z]').hasMatch(pw)) issues.add('It nhat 1 chu hoa');
    if (!RegExp(r'[0-9]').hasMatch(pw)) issues.add('It nhat 1 chu so');
    String label = score < 2 ? 'Yeu' : score < 3 ? 'Trung binh' : score < 4 ? 'Kha' : 'Manh';
    return PasswordStrength(score: score, label: label, issues: issues);
  }

  bool _canSubmit() => _newPassword.length >= 8 && _newPassword == _confirmPassword && _otp.length == 6 && _email != null;
}

