import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Secure storage wrapper using SharedPreferences.
/// Tokens are base64 obfuscated, PINs are SHA-256 hashed.
class SecureStorage {
  static const _kAccessToken = 'sec_access_token';
  static const _kRefreshToken = 'sec_refresh_token';
  static const _kUsername = 'sec_username';
  static const _kUserId = 'sec_user_id';
  static const _kPinHash = 'sec_pin_hash';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readAccessToken() async => (await _prefs).getString(_kAccessToken);
  Future<void> writeAccessToken(String token) async {
    final p = await _prefs;
    await p.setString(_kAccessToken, base64Encode(utf8.encode(token)));
  }

  Future<String?> readRefreshToken() async => (await _prefs).getString(_kRefreshToken);
  Future<void> writeRefreshToken(String token) async {
    final p = await _prefs;
    await p.setString(_kRefreshToken, base64Encode(utf8.encode(token)));
  }

  Future<String?> readUsername() async => (await _prefs).getString(_kUsername);
  Future<void> writeUsername(String username) async {
    final p = await _prefs;
    await p.setString(_kUsername, username);
  }

  Future<String?> readUserId() async => (await _prefs).getString(_kUserId);
  Future<void> writeUserId(String userId) async {
    final p = await _prefs;
    await p.setString(_kUserId, userId);
  }

  Future<void> writePin(String pin) async {
    final p = await _prefs;
    await p.setString(_kPinHash, _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final p = await _prefs;
    final stored = p.getString(_kPinHash);
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  Future<bool> hasPin() async {
    final p = await _prefs;
    return p.containsKey(_kPinHash);
  }

  Future<void> deleteAll() async {
    final p = await _prefs;
    await p.remove(_kAccessToken);
    await p.remove(_kRefreshToken);
    await p.remove(_kUsername);
    await p.remove(_kUserId);
  }

  Future<void> deleteEverything() async {
    final p = await _prefs;
    await p.clear();
  }

  String _hash(String value) {
    return sha256.convert(utf8.encode('dms_salt_${value}_2026')).toString();
  }
}
