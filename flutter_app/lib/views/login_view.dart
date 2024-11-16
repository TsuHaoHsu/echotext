import 'package:echotext/components/dialog_popup.dart';
import 'package:echotext/constants/exception.dart';
import 'package:echotext/constants/routes.dart';
import 'package:echotext/provider/state_provider.dart';
import 'package:echotext/requests/get_friend_list.dart';
import 'package:echotext/requests/get_user_list.dart';
import 'package:echotext/requests/login_user.dart';
import 'package:echotext/services/token_service.dart';
import 'package:echotext/services/user_service.dart';
import 'dart:developer' as devtools show log;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            onPressed: () async {
              // Add your login logic here
              TokenService tokenService = TokenService();
              try {
                //final currUser = await loginUser("abc@gmail.com", "12345"); //Jason Strong
                final currUser = await loginUser("cba@gmail.com", "12345"); //Hank Strong
                UserService.setUserId = currUser['user_id'];
                UserService.setName = currUser['name'];

                bool hasToken = await tokenService.hasAccessToken();

                if (hasToken) {
                  // Proceed to the next screen, as user is logged in
                  await getFriendList(UserService.userId!);
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(contactRoute,(Route<dynamic> route) => false);
                } else {
                  // Handle the case where the token isn't available
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
                await dialogPopup(
                    context, "An error occurred", "Invalid Email Format.");
              } on EmailNotVerifiedException {
                if (!context.mounted) return;
                await dialogPopup(context, "Email not verified",
                    "Please check your inbox for verification link.");
              } on ConnectionTimedOutException {
                if (!context.mounted) return;
                await dialogPopup(context, "An error occurred",
                    "Connection timed out, Please try again later.");
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
