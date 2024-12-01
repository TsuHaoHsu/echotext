import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'package:echotext/constants/exception.dart';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'package:echotext/models/user.dart';
import 'package:echotext/services/token_service.dart';

Future <Map<String,dynamic>> loginUser(
  String email,
  String password,
) async {
  final TokenService tokenService = TokenService();

  try {
    final url = Uri.parse("${uriHTTP}user/login");
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
        name: userData['name'],
        email: email,
        //isVerified: userData['isVerified'], /////////////////////////
      );
      devtools
          .log("User ${currUser.name} login successfully: id-${currUser.id}");

      final accessToken = userData['access_token'];
      final refreshToken = userData['refresh_token'];
      await tokenService.storeAccessToken(accessToken);
      await tokenService.storeRefreshToken(refreshToken);
      return {'user_id': currUser.id!, 'name':currUser.name!};
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
    devtools.log(e.toString());
    rethrow;
  }
  throw Exception("Unexpected error during login");
}
