import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:developer' as devtools show log;

class TokenService {
  // Private constructor
  TokenService._privateConstructor();

  // Static variable to hold the single instance of the class
  static final TokenService _instance = TokenService._privateConstructor();

  // Public factory constructor to access the singleton instance
  factory TokenService() {
    return _instance;
  }

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
  return accessToken != null && accessToken.isNotEmpty;  // Also check for empty string
}

  Future<bool> hasRefreshToken() async {
    String? refreshToken = await _secureStorage.read(key: 'refresh_token');
    return refreshToken != null;
  }

  Future<bool> hasAccessTokenExpired() async {
    String? accessToken = await getAccessToken();

    if (accessToken == null) {
      return true;
    }

    try {
      // Decode the token
      final jwt = JWT.decode(accessToken);
      
      // Get the expiration date from the token
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(jwt.payload['exp'] * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      // If decoding fails (invalid token), assume it's expired
      return true;
    }
  }

  Future<bool> isTokenStillValid() async {
    bool tokenExists = await hasAccessToken();

    if(tokenExists){
      return !await hasAccessTokenExpired();
    }

    return false;
  }
}