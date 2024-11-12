import 'package:echotext/components/contact_popup.dart';
import 'package:echotext/components/user_search_popup.dart';
import 'package:echotext/constants/routes.dart';
import 'package:echotext/requests/get_friend_list.dart';
import 'package:echotext/services/auth_service.dart';
import 'package:echotext/services/token_service.dart';
import 'package:echotext/services/user_service.dart';
import 'package:echotext/views/login_view.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class ContactView extends StatefulWidget {
  ContactView({super.key});
  final String? userId = UserService.userId;

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _friendList = [];

  @override
  void initState() {
    super.initState();
    _checkAccessToken();
    _fetchFriendList();
  }

  Future<void> _fetchFriendList() async {
    await UserService.fetchFriendList();
    setState(() {
      _friendList = UserService.friendList ?? [];
    });
  }

  Future<void> _checkAccessToken() async {
    if (!await TokenService().hasAccessToken()) {
      _authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled:
                    true, // Ensures the sheet can have a custom height,
                builder: (BuildContext context) {
                  return const FriendSearchPopup();
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
                devtools.log("User ${widget.userId} logging out...");
                _authService.logout();
                Navigator.of(context).pushReplacementNamed(loginRoute);
              }
            },
          )
        ],
      ),
      body: _friendList.isEmpty
          ? const Center(child: Text('No friends found'))
          : ListView.builder(
              itemCount: _friendList.length,
              itemBuilder: (context, index) {
                final friend = _friendList[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(friend['name'] ?? 'Unknown id'),
                  onTap: () {},
                );
              },
            ),
    );
  }
}
