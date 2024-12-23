import 'package:echotext/components/dialog_popup.dart';
import 'package:echotext/constants/exception.dart';
import 'package:echotext/constants/routes.dart';
import 'package:echotext/requests/get_friend_list.dart';
import 'package:echotext/requests/login_user.dart';
import 'package:echotext/services/token_service.dart';
import 'package:echotext/services/user_service.dart';
import 'dart:developer' as devtools show log;
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

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
          TextField(
            decoration: const InputDecoration(
              hintText: 'Username here',
            ),
            controller: _emailController,
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
                    setState(() {
                      _isLoading = true;
                    });

                    TokenService tokenService = TokenService();
                    try {
                      final currUser = await loginUser(
                          _emailController.text, _passwordController.text);
                      UserService.setUserId = currUser['user_id'];
                      UserService.setName = currUser['name'];

                      bool hasToken = await tokenService.hasAccessToken();

                      if (hasToken) {
                        await getFriendList(UserService.userId!);
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            contactRoute, (Route<dynamic> route) => false);
                      } else {
                        if (!context.mounted) return;
                        await dialogPopup(
                            context, "An error occurred", "Token not found.");
                      }
                    } on WrongPasswordException {
                      if (!context.mounted) return;
                      await dialogPopup(
                          context, "An error occurred", "Wrong Password.");
                    } on UserNotFoundException {
                      if (!context.mounted) return;
                      await dialogPopup(
                          context, "An error occurred", "User does not exist.");
                    } on InvalidEmailException {
                      if (!context.mounted) return;
                      await dialogPopup(context, "An error occurred",
                          "Invalid Email Format.");
                    } on EmailNotVerifiedException {
                      if (!context.mounted) return;
                      await dialogPopup(context, "Email not verified",
                          "Please check your inbox for verification link.");
                    } on ConnectionTimedOutException {
                      if (!context.mounted) return;
                      await dialogPopup(context, "An error occurred",
                          "Connection timed out, Please try again later.");
                    } catch (e) {
                      if (!context.mounted) return;
                      await dialogPopup(context, "An error occurred",
                          "FastAPI or Ngrok offline, Please try again later.");
                    } finally {
                      setState(() {
                        _isLoading = false; // Stop loading after the async task
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
            child: _isLoading ? const CircularProgressIndicator(
              color: Colors.white,
            ) : const Text('Login'),
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
