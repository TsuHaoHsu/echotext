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
  late Future<List<Map<String, dynamic>>> _friendList;

  @override
  void initState() {
    super.initState();
    _checkAccessToken();

    _friendList = Future.value([]);

    if (widget.userId != null) {
      _friendList = getFriendList(widget.userId!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authService.logout();
        Navigator.of(context).pushReplacementNamed(loginRoute);
      });
    }
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _friendList,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case (ConnectionState.waiting):
                return const Center(
                  child: CircularProgressIndicator(),
                );
              case (ConnectionState.done):
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No friends found'));
                } else {
                  final friendList = snapshot.data!;
                  return ListView.builder(
                      itemCount: friendList.length,
                      itemBuilder: (context, index) {
                        final friend = friendList[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(friend['name'] ?? 'Unknown id'),
                          onTap: () {},
                        );
                      });
                }
              default:
                return const Center(child: Text('Unexpected Error'));
            }
          }),
    );
  }
}
