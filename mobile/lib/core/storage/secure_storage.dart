import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessToken = 'access_token';
  static const _refreshToken = 'refresh_token';
  static const _userData = 'user_data';

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessToken, value: token);

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshToken, value: token);

  static Future<void> saveUserData(String json) =>
      _storage.write(key: _userData, value: json);

  static Future<String?> getAccessToken() => _storage.read(key: _accessToken);

  static Future<String?> getRefreshToken() => _storage.read(key: _refreshToken);

  static Future<String?> getUserData() => _storage.read(key: _userData);

  static Future<void> clear() => _storage.deleteAll();
}
