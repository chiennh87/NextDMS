// ============================================================================
// Main App Entry - DMS Sales Rep Mobile App - Enterprise FMCG
// ============================================================================
// Features: Approval Workflow, Offline-First Sync, Multi-Country, Data Scoping

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'core/storage/local_db.dart';
import 'core/storage/sync_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/outlet/repository/outlet_repository.dart';
import 'features/outlet/bloc/outlet_onboarding_bloc.dart';
import 'features/outlet/bloc/outlet_onboarding_event.dart';
import 'features/outlet/screens/create_outlet_screen.dart';
import 'features/outlet/screens/outlet_drafts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khoi tao dependencies theo DI thu cong (co the nang cap len get_it)
  final apiClient = ApiClient(baseUrl: 'http://10.0.2.2:3001/api/v1');
  final secureStorage = SecureStorage();
  final localDb = await LocalDb.create();
  final authRepository = AuthRepository(apiClient: apiClient, storage: secureStorage);
  final outletRepository = OutletRepository(apiClient: apiClient, storage: secureStorage);

  // SyncService - Enterprise Offline-First (auto-retry khi online)
  final syncService = SyncService(
    localDb: localDb,
    repository: outletRepository,
  );
  syncService.start();

  runApp(MyApp(
    apiClient: apiClient,
    secureStorage: secureStorage,
    localDb: localDb,
    syncService: syncService,
    authRepository: authRepository,
    outletRepository: outletRepository,
  ));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  final SecureStorage secureStorage;
  final LocalDb localDb;
  final SyncService syncService;
  final AuthRepository authRepository;
  final OutletRepository outletRepository;

  const MyApp({
    super.key,
    required this.apiClient,
    required this.secureStorage,
    required this.localDb,
    required this.syncService,
    required this.authRepository,
    required this.outletRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<SecureStorage>.value(value: secureStorage),
        RepositoryProvider<LocalDb>.value(value: localDb),
        RepositoryProvider<SyncService>.value(value: syncService),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<OutletRepository>.value(value: outletRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (ctx) => AuthBloc(
              repository: ctx.read<AuthRepository>(),
              storage: ctx.read<SecureStorage>(),
            )..add(const CheckAuthStatusEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'DMS Sales',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
          routes: {
            '/create-outlet': (ctx) => BlocProvider<OutletOnboardingBloc>(
              create: (ctx) => OutletOnboardingBloc(
                repository: ctx.read<OutletRepository>(),
                localDb: ctx.read<LocalDb>(),
                syncService: ctx.read<SyncService>(),
              )..add(const OutletOnboardingInitialized()),
              child: const CreateOutletScreen(),
            ),
            '/outlet/drafts': (ctx) => BlocProvider<OutletOnboardingBloc>(
              create: (ctx) => OutletOnboardingBloc(
                repository: ctx.read<OutletRepository>(),
                localDb: ctx.read<LocalDb>(),
                syncService: ctx.read<SyncService>(),
              ),
              child: const OutletDraftsScreen(),
            ),
          },
        ),
      ),
    );
  }
}