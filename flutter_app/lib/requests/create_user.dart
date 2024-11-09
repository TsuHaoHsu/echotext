import 'dart:convert';
import 'package:echotext/components/exception.dart';
import 'package:echotext/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;
import 'package:flutter/material.dart';

Future<void> createUser(
  BuildContext context,
  String email,
  String name,
  String password,
  //bool isVerified,
) async {
  try{
  final response = await http.post(
    Uri.parse("http://192.168.0.195:8000/user/"),
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
    devtools.log("User ${newUser.name} created successfully: id-${newUser.id}");
  } else {
    final errorData = jsonDecode(response.body);
    devtools.log('Full error data: ${errorData.toString()}');

    if (errorData['detail'].trim() == 'User with this email already exists.') {
      throw EmailAlreadyInUseException();
    } else {
      devtools.log(errorData.toString());
      throw ConnectionTimedOutException(); // Optionally throw a general error
    }
  }} catch (e) {
    if (e is! EmailAlreadyInUseException) {
        devtools.log('Error: ${e.toString()}');
        throw ConnectionTimedOutException();
    }
    else{
      rethrow;
    }
  }
}
