import 'package:echotext/components/contact_popup.dart';
import 'package:echotext/components/friend_search_popup.dart';
import 'package:echotext/constants/routes.dart';
import 'package:echotext/services/auth_service.dart';
import 'package:echotext/services/token_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAccessToken();
  }

  Future<void> _checkAccessToken() async {
    if (!await TokenService().hasAccessToken()) {
      _authService.logout();
    }
  }

  final List<String> contacts = [
    "Jason",
    "Hank",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          actions: [
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled:
                      true, // Ensures the sheet can have a custom height,
                  builder: (BuildContext context) {
                    return FriendSearchPopup();
                  },
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
            ),
            PopupMenuButton<String>(
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Sign Out',
                  child: Text('Sign Out'),
                ),
              ],
              onSelected: (String result) {
                if (result == 'Sign Out') {
                  devtools.log("User logging out...");
                  _authService.logout();
                  Navigator.of(context).pushReplacementNamed(loginRoute);
                }
              },
            )
          ],
        ),
        body: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(contacts[index]),
                onTap: () => {
                  // open each contact
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return ContactPopup(contactName: contacts[index]);
                    },
                  )
                },
              );
            }));
  }
}
