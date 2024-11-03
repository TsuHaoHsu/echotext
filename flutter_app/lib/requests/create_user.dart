import 'dart:convert';
import 'package:echotext/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;
import 'package:flutter/material.dart';


Future<void> createUser(String email, String name, String password) async {
  final response = await http.post(
    Uri.parse("http://192.168.0.195:8000/user/"),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'name': name,
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final userData = jsonDecode(response.body);
    final newUser = User(
      id: userData['id'],
      email: email,
      name: name,
      password: password,
    );
    devtools.log("User ${newUser.name} created successfully: id-${newUser.id}");
  } else{
    
  }
}