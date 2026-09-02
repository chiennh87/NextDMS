import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient(baseUrl: 'http://localhost:3000/api/v1');
  final secureStorage = SecureStorage();
  final authRepository = AuthRepository(apiClient: apiClient, storage: secureStorage);

  runApp(MyApp(
    apiClient: apiClient,
    secureStorage: secureStorage,
    authRepository: authRepository,
  ));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  final SecureStorage secureStorage;
  final AuthRepository authRepository;

  const MyApp({
    super.key,
    required this.apiClient,
    required this.secureStorage,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: secureStorage),
        RepositoryProvider.value(value: authRepository),
      ],
      child: BlocProvider(
        create: (ctx) => AuthBloc(
          repository: ctx.read<AuthRepository>(),
          storage: ctx.read<SecureStorage>(),
        ),
        child: MaterialApp(
          title: 'DMS Sales',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
