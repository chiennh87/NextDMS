// Forgot password & reset password models
class ForgotPasswordRequest {
  final String email;
  const ForgotPasswordRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordResponse {
  final bool success;
  final String message;
  final int expiresIn;
  const ForgotPasswordResponse({
    required this.success,
    required this.message,
    required this.expiresIn,
  });
  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        expiresIn: json['expires_in'] ?? 300,
      );
}

class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;
  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
    'new_password': newPassword,
  };
}

class ResetPasswordResponse {
  final bool success;
  final String message;
  final int sessionsRevoked;
  const ResetPasswordResponse({
    required this.success,
    required this.message,
    required this.sessionsRevoked,
  });
  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) =>
      ResetPasswordResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        sessionsRevoked: json['sessions_revoked'] ?? 0,
      );
}

class PasswordStrength {
  final int score; // 0-4
  final String label; // Weak, Fair, Good, Strong
  final List<String> issues;
  const PasswordStrength({
    required this.score,
    required this.label,
    required this.issues,
  });
  static const empty = PasswordStrength(score: 0, label: 'Empty', issues: []);
}
