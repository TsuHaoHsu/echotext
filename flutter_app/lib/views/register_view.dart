import 'package:echotext/components/dialog_popup.dart';
import 'package:echotext/constants/exception.dart';
import 'package:echotext/constants/routes.dart';
import 'package:echotext/requests/create_user.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

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
              TextField(
                decoration: const InputDecoration(
                  hintText: 'User email here',
                ),
                controller: _emailController,
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Username here',
                ),
                controller: _nameController,
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Password here',
                ),
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 32.0), // Increase space before the button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState((){
                          _isLoading = true;
                        });
                        try {
                          await createUser(
                            _emailController.text,
                            _nameController.text,
                            _passwordController.text,
                          );
                          if (!context.mounted) return;
                          await dialogPopup(
                              context, "Success!", "Account has been created.");
                          if (!context.mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            loginRoute,
                            (Route<dynamic> route) => false,
                          );
                        } on EmailAlreadyInUseException {
                          devtools.log(
                              'Caught EmailAlreadyInUseException in register_view');
                          if (!context.mounted) return;
                          await dialogPopup(context, "An error occurred",
                              "Email already in use.");
                        } on ConnectionTimedOutException {
                          if (!context.mounted) return;
                          await dialogPopup(context, "An error occurred",
                              "Connection timed out.");
                        } on InvalidEmailException {
                          devtools.log('Caught Invalid Email in register_view');
                          if (!context.mounted) return;
                          await dialogPopup(context, "An error occurred",
                              "Invalid Email Format.");
                        } on WeakPasswordException {
                          devtools.log(
                              'Caught WeakPasswordException in register_view');
                          if (!context.mounted) return;
                          await dialogPopup(context, "An error occurred",
                              "Password must have at least 6 characters.");
                        } on GenericException {
                          if (!context.mounted) return;
                          await dialogPopup(
                              context, "An error occurred", "Generic Error");
                        } finally {
                        setState((){
                          _isLoading = false;
                        });
                        }
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
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Register'),
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
