import 'dart:convert';
import 'package:echotext/constants/exception.dart';
import 'package:echotext/constants/uri.dart';
import 'package:echotext/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<void> createUser(
  String email,
  String name,
  String password,
  //bool isVerified,
) async {
  try {
    final response = await http.post(
      Uri.parse("${uriHTTP}user/"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, String>{
          'name': name,
          'email': email,
          'password': password,
        },
      ),
    );
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final newUser = User(
        id: userData['id'],
        email: email,
        name: name,
        //password: password,
        //isVerified: false,
      );
      devtools
          .log("User ${newUser.name} created successfully: id-${newUser.id}");
    } else {
      final errorData = jsonDecode(response.body);
      devtools.log('Full error data: ${errorData.toString()}');

      if (errorData['detail']
          .toString()
          .contains('not a valid email address')) {
        throw InvalidEmailException(); // Custom exception for invalid email format
      } else if (errorData['detail']
          .toString()
          .contains('User with this email already exists.')) {
        throw EmailAlreadyInUseException(); // Existing case
      } else if (errorData['detail'] is List &&
          errorData['detail'][0]['msg']
              .toString()
              .contains('String should have at least 6 characters')) {
        throw WeakPasswordException();
      } else {
        // Handle other specific server-side errors here if needed
        devtools.log('Unhandled error: ${errorData.toString()}');
        throw GenericException(); // A more general server-side error
      }
    }
  } catch (e) {
    if (e is EmailAlreadyInUseException) {
      rethrow; // Let the specific exception propagate
    } else if (e is InvalidEmailException) {
      rethrow;
    } else if (e is WeakPasswordException) {
      rethrow;
    } else if (e is ConnectionTimedOutException) {
      devtools.log('Error: Timeout occurred: ${e.toString()}');
      throw ConnectionTimedOutException(); // Explicit timeout handling
    } else {
      devtools.log('Unexpected Error: ${e.toString()}');
      throw GenericException(); // Catch-all for other unexpected errors
    }
  }
}
