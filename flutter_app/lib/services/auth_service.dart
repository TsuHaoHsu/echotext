import 'dart:convert';
import 'package:echotext/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

class AuthService {
  final TokenService _tokenService = TokenService();

  Future<bool> isLoggedIn() async {
    final hasAccessToken = await _tokenService.hasAccessToken();
    return hasAccessToken;
  }

  Future<void> logout() async {
    await _tokenService.clearToken();
  }

  Future<bool> refreshAccessToken() async {
    final hasRefreshToken = await _tokenService.hasRefreshToken();

    if (hasRefreshToken) {
      final refreshToken = await _tokenService.getRefreshToken();
      
      // Step 2: Send the refresh token to the backend to get a new access token
      if (refreshToken != null) {
      final response = await _refreshAccessTokenFromAPI(refreshToken);

        if (response != null){
          await _tokenService.storeAccessToken(response['access_token']);
          if (response['refresh_token'] != null) {
            await _tokenService.storeRefreshToken(response['refresh_token']);
          }

        return true;
        }
      }
    }
    return false;
  }

  Future<Map<String,dynamic>?> _refreshAccessTokenFromAPI(String refreshToken) async {

    const String apiUrl = "http://192.168.0.195:8000/user/refresh-token";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'refresh_token': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

}