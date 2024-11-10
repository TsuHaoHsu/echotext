import 'package:echotext/constants/routes.dart';
import 'package:echotext/services/auth_service.dart';
import 'package:echotext/services/token_service.dart';
import 'package:echotext/views/contact_view.dart';
import 'package:echotext/views/login_view.dart';
import 'package:echotext/views/register_view.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkAccessToken() async {
    final hasToken = await TokenService().hasAccessToken();
    return hasToken;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
          future: _checkAccessToken(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              case ConnectionState.done:
                if (snapshot.hasData && snapshot.data == true) {
                  return ContactView();
                } else {
                  return const LoginView();
                }
              case ConnectionState.none:
              case ConnectionState.active:
                return const CircularProgressIndicator();

              default:
                return const LoginView();
            }
          }),
      //home: const ContactView(),
      routes: {
        contactRoute: (context) => ContactView(),
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
      },
      debugShowCheckedModeBanner: false, // remove the banner top right
    );
  }
}
