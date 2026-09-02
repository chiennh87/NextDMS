import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class OfflineLoginScreen extends StatefulWidget {
  const OfflineLoginScreen({super.key});
  @override
  State<OfflineLoginScreen> createState() => _OfflineLoginScreenState();
}

class _OfflineLoginScreenState extends State<OfflineLoginScreen> {
  String _pin = '';
  static const String _correctPin = '123456';

  void _onKey(String k) {
    if (_pin.length < 6) {
      setState(() => _pin += k);
      if (_pin.length == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_pin == _correctPin) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else {
            setState(() => _pin = '');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sai PIN. Thu lai'), backgroundColor: Colors.red),
            );
          }
        });
      }
    }
  }

  void _onClear() {
    setState(() {
      _pin = _pin.isNotEmpty ? _pin.substring(0, _pin.length - 1) : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dang nhap Offline'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange),
                SizedBox(width: 12),
                Text('Che do Offline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (i) => Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1976D2), width: 2),
                  color: _pin.length > i ? const Color(0xFF1976D2) : Colors.transparent,
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildKeypadRow(['1', '2', '3']),
                _buildKeypadRow(['4', '5', '6']),
                _buildKeypadRow(['7', '8', '9']),
                _buildKeypadRow(['X', '0', '']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => k.isEmpty ? const SizedBox(width: 72, height: 72) : _buildKey(k)).toList(),
    );
  }

  Widget _buildKey(String k) {
    final isBack = k == 'X';
    return GestureDetector(
      onTap: () {
        if (isBack) {
          _onClear();
        } else {
          _onKey(k);
        }
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: isBack ? const Icon(Icons.backspace_outlined, size: 28) : Text(k, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
