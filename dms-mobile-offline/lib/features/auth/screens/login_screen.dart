import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'offline_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'sales01');
  final _passwordCtrl = TextEditingController(text: 'Sales@123');
  final _deviceIdCtrl = TextEditingController(text: 'DEV-001');
  bool _obscure = true;
  bool _isOnline = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    if (_isOnline) {
      context.read<AuthBloc>().add(LoginEvent(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        deviceId: _deviceIdCtrl.text.trim(),
      ));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OfflineLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2, size: 48, color: Color(0xFF1976D2)),
                    ),
                    const SizedBox(height: 16),
                    const Text('DMS Sales', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('FMCG Distribution', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTab('Online', _isOnline, () => setState(() => _isOnline = true)),
                          _buildTab('Offline PIN', !_isOnline, () => setState(() => _isOnline = false)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isOnline) ..._buildOnlineForm(loading) else _buildOfflineHint(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: const Text('Quen mat khau?', style: TextStyle(color: Color(0xFF1976D2))),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? const Color(0xFF1976D2) : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOnlineForm(bool loading) {
    return [
      _buildField('Tai khoan', _usernameCtrl, Icons.person, false),
      const SizedBox(height: 16),
      _buildField('Mat khau', _passwordCtrl, Icons.lock, true),
      const SizedBox(height: 16),
      _buildField('Device ID', _deviceIdCtrl, Icons.devices, false, readOnly: true),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: loading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Dang Nhap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    ];
  }

  Widget _buildOfflineHint() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.wifi_off, size: 48, color: Colors.orange),
          SizedBox(height: 12),
          Text('Che do Offline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          SizedBox(height: 8),
          Text('Su dung PIN 6 so da dang ky truoc do', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, bool isPassword, {bool readOnly = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword && _obscure,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Nhap $label' : null,
    );
  }
}
