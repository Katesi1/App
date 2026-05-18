import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessToken = 'access_token';
  static const _refreshToken = 'refresh_token';
  static const _userData = 'user_data';
  static const _savedPhone = 'saved_email';
  static const _savedPassword = 'saved_password';

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessToken, value: token);

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshToken, value: token);

  static Future<void> saveUserData(String json) =>
      _storage.write(key: _userData, value: json);

  static Future<String?> getAccessToken() => _storage.read(key: _accessToken);

  static Future<String?> getRefreshToken() => _storage.read(key: _refreshToken);

  static Future<String?> getUserData() => _storage.read(key: _userData);

  /// Save login credentials (phone + password) when the user ticks "Remember".
  /// Kept separate from auth tokens so [clear] on logout does not erase them.
  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _savedPhone, value: email);
    await _storage.write(key: _savedPassword, value: password);
  }

  static Future<({String email, String password})?>
      getSavedCredentials() async {
    final email = await _storage.read(key: _savedPhone);
    final password = await _storage.read(key: _savedPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _savedPhone);
    await _storage.delete(key: _savedPassword);
  }

  /// Clear auth tokens + user data on logout. Does NOT clear saved credentials.
  static Future<void> clear() async {
    await _storage.delete(key: _accessToken);
    await _storage.delete(key: _refreshToken);
    await _storage.delete(key: _userData);
  }
}
