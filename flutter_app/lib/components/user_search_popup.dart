import 'package:echotext/services/user_list_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class FriendSearchPopup extends StatefulWidget {
  const FriendSearchPopup({super.key});

  @override
  State<FriendSearchPopup> createState() => _FriendSearchPopupState();
}

class _FriendSearchPopupState extends State<FriendSearchPopup> {
  late TextEditingController _controller;
  List<Map<String, dynamic>> _userList = []; // List of all users
  List<Map<String, dynamic>> _filteredUserList = []; // List of all filtered users

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _fetchUserList(); // Load user list on start
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fetchUserList() async {
    try{
      List<Map<String, dynamic>> users = await getUserList();
      setState((){
        _userList = users;
        _filteredUserList = users; // Initally, show all users
      });
    }catch(e){
      devtools.log("Failed to get user list");
    }
  }

  void _filterUsers(String query){
    final filteredList = _userList.where((user){
      return user['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredUserList = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          ],
        ),
      ),
    );
  }
}
