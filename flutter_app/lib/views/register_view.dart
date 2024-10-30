import 'package:echotext/constants/routes.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Register'),
          backgroundColor: const Color.fromARGB(
              255, 198, 96, 216), // Set your desired color h
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                child: const Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Already have an account'),
              ),
            ],
          ),
        ));
  }
}
