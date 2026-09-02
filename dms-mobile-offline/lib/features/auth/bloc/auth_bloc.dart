// AuthBloc - xu ly login, logout, auth status
// Enterprise: Luu UserSession voi distributor_id, territory_id (Data Isolation)

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/storage/secure_storage.dart';
import '../repository/auth_repository.dart';
import '../models/user_session.dart';

// ============ EVENTS ============

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  final String deviceId;
  const LoginEvent({required this.username, required this.password, required this.deviceId});
  @override
  List<Object?> get props => [username, password, deviceId];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LogoutEvent extends AuthEvent {
  final bool logoutAll;
  const LogoutEvent({this.logoutAll = false});
  @override
  List<Object?> get props => [logoutAll];
}

// ============ STATES ============

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  // Enterprise: Session chua distributor_id + territory_id cho Data Isolation
  final UserSession session;
  const AuthAuthenticated(this.session);
  @override
  List<Object?> get props => [session.userId, session.username];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthLoggingOut extends AuthState {
  const AuthLoggingOut();
}

class AuthLoggedOut extends AuthState {
  final String message;
  const AuthLoggedOut(this.message);
  @override
  List<Object?> get props => [message];
}

// ============ BLOC ============

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final SecureStorage storage;

  AuthBloc({required this.repository, required this.storage}) : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await repository.login(
        username: event.username,
        password: event.password,
        deviceId: event.deviceId,
      );

      await storage.writeAccessToken(response['access_token'] as String);
      await storage.writeRefreshToken(response['refresh_token'] as String);
      await storage.writeUsername(event.username);

      // Enterprise: Tao UserSession voi scoping
      final session = UserSession.fromJson(response['user'] as Map<String, dynamic>? ?? {});
      await storage.writeUserSession(jsonEncode(response['user']));
      await storage.writeUserId(session.userId.toString());

      emit(AuthAuthenticated(session));
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('network') || msg.contains('SocketException')) {
        emit(const AuthError('Khong co ket noi mang. Vui long kiem tra internet.'));
      } else if (msg.contains('401') || msg.contains('Unauthorized')) {
        emit(const AuthError('Tai khoan hoac mat khau khong dung.'));
      } else if (msg.contains('timeout')) {
        emit(const AuthError('Server khong phan hoi. Thu lai sau.'));
      } else {
        emit(AuthError('Dang nhap that bai: $msg'));
      }
    }
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final token = await storage.readAccessToken();
    if (token != null) {
      // Thu build UserSession tu local storage
      final sessionJson = await storage.readUserSession();
      if (sessionJson != null) {
        try {
          final session = UserSession.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>);
          emit(AuthAuthenticated(session));
          return;
        } catch (_) {}
      }
      // Fallback: tao session co ban
      final username = await storage.readUsername() ?? 'unknown';
      emit(AuthAuthenticated(UserSession(
        userId: 0, username: username, fullName: username,
        distributorId: 1, territoryId: 1, role: 'SALES_REP',
      )));
    } else {
      emit(const AuthInitial());
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoggingOut());
    try {
      await repository.logout(logoutAll: event.logoutAll);
      await storage.deleteAll();
      emit(AuthLoggedOut(event.logoutAll ? 'Da dang xuat khoi tat ca thiet bi' : 'Da dang xuat thanh cong'));
    } catch (e) {
      await storage.deleteAll();
      emit(const AuthLoggedOut('Da dang xuat cuc bo'));
    }
  }
}