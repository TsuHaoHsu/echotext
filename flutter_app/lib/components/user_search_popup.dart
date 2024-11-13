import 'package:echotext/components/contact_popup.dart';
import 'package:echotext/components/dialog_popup.dart';
import 'package:echotext/requests/add_friend.dart';
import 'package:echotext/requests/get_user_list.dart';
import 'package:echotext/services/auth_service.dart';
import 'package:echotext/services/token_service.dart';
import 'package:echotext/services/user_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class UserSearchPopup extends StatefulWidget {
  const UserSearchPopup({super.key});

  @override
  State<UserSearchPopup> createState() => _UserSearchPopupState();
}

class _UserSearchPopupState extends State<UserSearchPopup> {
  late TextEditingController _controller;
  List<Map<String, dynamic>> _userList = []; // List of all users
  List<Map<String, dynamic>> _filteredUserList =
      []; // List of all filtered users
  late Future<List<Map<String, dynamic>>> _friendList;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _friendList = Future.value([]);
    _checkAccessToken();
    _fetchUserList(); // Load user list on start
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAccessToken() async {
    if (!await TokenService().hasAccessToken()) {
      AuthService authService = AuthService();
      authService.logout();
    }
  }

  void _fetchUserList() async {
    try {
      List<Map<String, dynamic>> users = await getUserList("");
      setState(() {
        _userList = users;
        _filteredUserList = users; // Initally, show all users
      });
    } catch (e) {
      devtools.log("Failed to get user list: $e");
    }
  }

  void _filterUsers(String query) {
    final filteredList = _userList.where((user) {
      return user['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredUserList = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type the name of other people',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      _filterUsers(query);
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: _filteredUserList.length,
                  itemBuilder: (context, index) {
                    final filteredUsers = _filteredUserList[index];
                    String profilePictureUrl =
                        filteredUsers['profile_picture'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: profilePictureUrl.isEmpty
                            ? const AssetImage(
                                'assets/images/default_avatar.png')
                            : NetworkImage(profilePictureUrl) as ImageProvider,
                      ),
                      title: Text(filteredUsers['name'] ?? 'Unknown User'),
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              final bool isNetworkImage =
                                  profilePictureUrl.startsWith('http');
                              return ContactPopup(
                                userId: filteredUsers['user_id'],
                                userName:
                                    filteredUsers['name'] ?? 'Unknown User',
                                profilePicture: isNetworkImage
                                    ? profilePictureUrl
                                    : 'assets/images/default_avatar.png',
                              );
                            });
                      },
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
