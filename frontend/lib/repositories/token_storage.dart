import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'jwt_access_token';

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String accessToken) {
    return _storage.write(key: accessTokenKey, value: accessToken);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<void> clearAccessToken() {
    return _storage.delete(key: accessTokenKey);
  }
}
