import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';

  Future<void> saveAuthToken({required String accessToken, required String tokenType}) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
  }
  
  Future<String?> readAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> readTokenType() async {
    return await _storage.read(key: _tokenTypeKey);
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenTypeKey);
  }
}