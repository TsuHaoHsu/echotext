import 'package:echotext/constants/routes.dart';
import 'package:echotext/views/contact_view.dart';
import 'package:echotext/views/login_view.dart';
import 'package:echotext/views/register_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final bool isLoggedIn = true; // Change to test logged-in route
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //home: isLoggedIn ? const ContactView() : const LoginView(),
      home: const ContactView(),
      routes: {
        contactRoute: (context) => const ContactView(),
        loginRoute : (context) => const LoginView(),
        registerRoute : (context) => const RegisterView(),
        },
      debugShowCheckedModeBanner: false, // remove the banner top right
    );
  }
}