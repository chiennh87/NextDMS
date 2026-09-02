import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorage storage;

  AuthRepository({required this.apiClient, required this.storage});

  /// Login with username/password/deviceId.
  /// Returns Map with access_token, refresh_token, user info.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final response = await apiClient.post('/auth/login', body: {
      'username': username,
      'password': password,
      'device_id': deviceId,
    });
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  /// Logout - revoke tokens via API.
  Future<void> logout({bool logoutAll = false}) async {
    final accessToken = await storage.readAccessToken();
    final refreshToken = await storage.readRefreshToken();

    if (accessToken != null && refreshToken != null) {
      try {
        await apiClient.post(
          '/auth/logout${logoutAll ? "?all=true" : ""}',
          body: {'refresh_token': refreshToken},
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Request OTP for forgot password.
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await apiClient.post('/auth/forgot-password', body: {'email': email});
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  /// Reset password with OTP.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await apiClient.post('/auth/reset-password', body: {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }

  /// Refresh access token.
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final res = await apiClient.post('/auth/refresh', body: {'refresh_token': refreshToken});
    return res is Map<String, dynamic> ? res : <String, dynamic>{};
  }
}
