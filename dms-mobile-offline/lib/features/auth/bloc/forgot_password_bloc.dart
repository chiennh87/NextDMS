import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/forgot_password_models.dart';

abstract class ForgotPasswordEvent {
  const ForgotPasswordEvent();
}

class RequestOTPEvent extends ForgotPasswordEvent {
  final String email;
  const RequestOTPEvent(this.email);
}

class VerifyOTPEvent extends ForgotPasswordEvent {
  final String email;
  final String otp;
  const VerifyOTPEvent(this.email, this.otp);
}

class ResendOTPEvent extends ForgotPasswordEvent {
  final String email;
  const ResendOTPEvent(this.email);
}

class ResetPasswordEvent extends ForgotPasswordEvent {
  final String email;
  final String otp;
  final String newPassword;
  const ResetPasswordEvent(this.email, this.otp, this.newPassword);
}

class UpdateCountdownEvent extends ForgotPasswordEvent {
  final int seconds;
  const UpdateCountdownEvent(this.seconds);
}

class ResetStateEvent extends ForgotPasswordEvent {
  const ResetStateEvent();
}

abstract class ForgotPasswordState {
  const ForgotPasswordState();
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class OTPRequested extends ForgotPasswordState {
  final String email;
  final int countdownSeconds;
  const OTPRequested({required this.email, this.countdownSeconds = 0});
}

class OTPResending extends ForgotPasswordState {
  final String email;
  const OTPResending({required this.email});
}

class PasswordReset extends ForgotPasswordState {
  final String message;
  const PasswordReset({required this.message});
}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;
  final ForgotPasswordErrorType type;
  const ForgotPasswordError(this.message, this.type);
}

enum ForgotPasswordErrorType {
  networkError,
  rateLimited,
  invalidOTP,
  passwordTooWeak,
  serverError,
}

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  Timer? _countdownTimer;
  String? _pendingEmail;
  String? _pendingOTP;

  ForgotPasswordBloc() : super(const ForgotPasswordInitial()) {
    on<RequestOTPEvent>(_onRequestOTP);
    on<VerifyOTPEvent>(_onVerifyOTP);
    on<ResendOTPEvent>(_onResendOTP);
    on<ResetPasswordEvent>(_onResetPassword);
    on<UpdateCountdownEvent>(_onUpdateCountdown);
    on<ResetStateEvent>(_onResetState);
  }

  Future<void> _onRequestOTP(RequestOTPEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(const ForgotPasswordLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      _pendingEmail = event.email;
      emit(OTPRequested(email: event.email, countdownSeconds: 60));
      _startCountdown();
    } catch (e) {
      emit(ForgotPasswordError(e.toString(), ForgotPasswordErrorType.networkError));
    }
  }

  Future<void> _onResendOTP(ResendOTPEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(OTPResending(email: event.email));
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(OTPRequested(email: event.email, countdownSeconds: 60));
      _startCountdown();
    } catch (e) {
      emit(ForgotPasswordError(e.toString(), ForgotPasswordErrorType.networkError));
    }
  }

  Future<void> _onVerifyOTP(VerifyOTPEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(const ForgotPasswordLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    _pendingOTP = event.otp;
    _pendingEmail = event.email;
    emit(OTPRequested(email: event.email, countdownSeconds: 60));
  }

  Future<void> _onResetPassword(ResetPasswordEvent event, Emitter<ForgotPasswordState> emit) async {
    emit(const ForgotPasswordLoading());
    try {
      final strength = _checkPasswordStrength(event.newPassword);
      if (strength.score < 2) {
        emit(ForgotPasswordError('Password too weak: ' + strength.issues.join(', '), ForgotPasswordErrorType.passwordTooWeak));
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
      _countdownTimer?.cancel();
      emit(const PasswordReset(message: 'Mat khau da duoc dat lai thanh cong!'));
    } catch (e) {
      if (e.toString().contains('OTP')) {
        emit(ForgotPasswordError('Ma OTP khong hop le hoac da het han', ForgotPasswordErrorType.invalidOTP));
      } else {
        emit(ForgotPasswordError(e.toString(), ForgotPasswordErrorType.serverError));
      }
    }
  }

  void _onUpdateCountdown(UpdateCountdownEvent event, Emitter<ForgotPasswordState> emit) {
    if (state is OTPRequested) {
      emit(OTPRequested(email: _pendingEmail ?? '', countdownSeconds: event.seconds));
    }
  }

  void _onResetState(ResetStateEvent event, Emitter<ForgotPasswordState> emit) {
    _countdownTimer?.cancel();
    _pendingEmail = null;
    _pendingOTP = null;
    emit(const ForgotPasswordInitial());
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    int seconds = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;
      if (seconds <= 0) timer.cancel();
      add(UpdateCountdownEvent(seconds));
    });
  }

  PasswordStrength _checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    int score = 0;
    List<String> issues = [];
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (password.length < 8) issues.add('It nhat 8 ky tu');
    if (!RegExp(r'[A-Z]').hasMatch(password)) issues.add('It nhat 1 chu hoa');
    if (!RegExp(r'[0-9]').hasMatch(password)) issues.add('It nhat 1 chu so');
    String label = score < 2 ? 'Yeu' : score < 3 ? 'Trung binh' : score < 4 ? 'Kha' : 'Manh';
    return PasswordStrength(score: score, label: label, issues: issues);
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
