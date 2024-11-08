import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'package:echotext/components/exception.dart';
import 'package:echotext/provider/state_provider.dart';
import 'package:http/http.dart' as http;
import 'package:echotext/models/user.dart';
import 'package:echotext/services/token_service.dart';

Future<void> loginUser(
  String email,
  String password,
) async {
  final TokenService tokenService = TokenService();

  try {
    final url = Uri.parse("http://192.168.0.195:8000/user/login");
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final currUser = User(
        id: userData['id'],
        email: email,
        //isVerified: userData['isVerified'], /////////////////////////
      );
      devtools
          .log("User ${currUser.email} login successfully: id-${currUser.id}");
      final accessToken = userData['access_token'];
      final refreshToken = userData['refresh_token'];
      await tokenService.storeAccessToken(accessToken);
      await tokenService.storeRefreshToken(refreshToken);
    } else {
      final errorData = jsonDecode(response.body);
      devtools.log('Failed to login: ${response.statusCode} ${response.body}');
      if (errorData['detail'] is List && errorData['detail'].isNotEmpty) {
        final errorDetail = errorData['detail'][0];
        if (errorDetail['msg']
            .toString()
            .contains("not a valid email address")) {
          throw InvalidEmailException();
        }
      } else if (errorData['detail'].trim() == '401: Incorrect Password') {
        throw WrongPasswordException();
      } else if (errorData['detail'].trim() == '404: User does not exist') {
        throw UserNotFoundException();
      } else if (errorData['detail'].trim() == '403: Email not yet verified') {
        throw EmailNotVerifiedException();
      } else {
        devtools.log(errorData.toString());
        throw ConnectionTimedOutException(); // Optionally throw a general error*/
      }
    }
  } catch (e) {
    rethrow;
  }
}
