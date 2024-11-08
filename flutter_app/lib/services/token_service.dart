import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> storeAccessToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  Future<void> storeRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> clearAccessToken() async {
    await _secureStorage.delete(key: 'access_token');
  }

  Future<void> clearRefreshToken() async {
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }
  
  Future<bool> hasAccessToken() async {
    String? accessToken = await _secureStorage.read(key: 'access_token');
    return accessToken != null;
  }

  Future<bool> hasRefreshToken() async {
    String? refreshToken = await _secureStorage.read(key: 'refresh_token');
    return refreshToken != null;
  }
}
