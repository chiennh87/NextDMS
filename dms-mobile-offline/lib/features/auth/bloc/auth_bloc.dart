import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/storage/secure_storage.dart';
import '../repository/auth_repository.dart';

// ===================== EVENTS =====================

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

// ===================== STATES =====================

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
  final String username;
  final String displayName;
  final String accessToken;
  const AuthAuthenticated({required this.username, required this.displayName, required this.accessToken});
  @override
  List<Object?> get props => [username, displayName, accessToken];
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

// ===================== BLOC =====================

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
      final response = await repository.login(username: event.username, password: event.password, deviceId: event.deviceId);
      await storage.writeAccessToken(response['access_token']);
      await storage.writeRefreshToken(response['refresh_token']);
      await storage.writeUsername(event.username);
      emit(AuthAuthenticated(
        username: event.username,
        displayName: response['user']?['display_name'] ?? event.username,
        accessToken: response['access_token'],
      ));
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
      final username = await storage.readUsername() ?? 'unknown';
      emit(AuthAuthenticated(username: username, displayName: username, accessToken: token));
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
