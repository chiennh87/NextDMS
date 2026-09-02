import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../repository/auth_repository.dart';
import '../../../core/storage/secure_storage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AuthBloc(
        repository: ctx.read<AuthRepository>(),
        storage: ctx.read<SecureStorage>(),
      ),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cai dat'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthLoggingOut) {
            showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          }
          if (state is AuthLoggedOut) {
            Navigator.of(ctx).popUntil((route) => route.isFirst);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
        },
        builder: (ctx, state) => ListView(
          children: [
            _profileCard(),
            const SizedBox(height: 16),
            _settingsTile('Thong tin ca nhan', Icons.person, () {}),
            _settingsTile('Thay doi mat khau', Icons.lock, () {}),
            _settingsTile('Thong bao', Icons.notifications, () {}),
            _settingsTile('Ngon ngu', Icons.language, () {}),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Dang xuat', style: TextStyle(color: Colors.red)),
              onTap: () => _showLogoutDialog(ctx, false),
            ),
            ListTile(
              leading: const Icon(Icons.devices, color: Colors.red),
              title: const Text('Dang xuat khoi tat ca thiet bi', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Thu hoi toan bo session dang nhap'),
              onTap: () => _showLogoutDialog(ctx, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFF1976D2),
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nguyen Van A', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('sales01@dms.local', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1976D2)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext ctx, bool all) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Xac nhan dang xuat'),
        content: Text(all ? 'Dang xuat khoi tat ca thiet bi?' : 'Dang xuat khoi thiet bi nay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dctx);
              ctx.read<AuthBloc>().add(LogoutEvent(logoutAll: all));
            },
            child: const Text('Dang xuat'),
          ),
        ],
      ),
    );
  }
}
