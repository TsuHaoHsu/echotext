import 'package:echotext/constants/routes.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color.fromARGB(
            255, 198, 96, 216), // Set your desired color here
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Username here',
            ),
          ),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Password here',
            ),
          ),
          const SizedBox(height: 32.0), // Increase space before the button
          ElevatedButton(
            onPressed: () {
              // Add your login logic here
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.deepPurple, // Text color
              padding: const EdgeInsets.symmetric(
                  horizontal: 22.0, vertical: 14.0), // Button padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
              ),
              elevation: 5, // Shadow effect
            ),
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute, (Route<dynamic> route) => false);
            },
            child: const Text('Create new account'),
          ),
        ]),
      ),
    );
  }
}
