import 'package:echotext/components/dialog_popup.dart';
import 'package:echotext/requests/add_friend.dart';
import 'package:echotext/requests/get_pending_request.dart';
import 'package:echotext/services/user_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class ContactPopup extends StatefulWidget {
  final String userId;
  final String userName;
  final String profilePicture;
  
  const ContactPopup(
      {super.key, required this.userName, required this.profilePicture, required this.userId, });

  @override
  State<ContactPopup> createState() => _ContactPopupState();
}

class _ContactPopupState extends State<ContactPopup> {
  late TextEditingController _controller;
  late String name = widget.userName;
  late String pic = widget.profilePicture;
  late String userId = widget.userId;
  late String currentUserId = UserService.userId!;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkRelationShipStatus() async {

    if (UserService.userId != null) {
      // Check for pending requests and friendship
      bool isFriend = UserService.friendList?.any((friend) => friend['user_id'] == widget.userId) ?? false;
    } else {
      // Handle the case where userId is null, e.g., show an error
      devtools.log("User ID is null");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: pic.startsWith('http')
                    ? NetworkImage(pic)
                    : AssetImage(pic) as ImageProvider,
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                            devtools.log("Friend request from ${UserService.userId!} to $name");
                            bool sc = await addFriend(UserService.userId!, userId);
                            if(!context.mounted) return;
                            if(sc == true){
                              dialogPopup(context, "Success", "Friend request sent");
                            } else{
                              dialogPopup(context, "Success", "Friend request canceled");
                            }
                          },
                icon: const Icon(Icons.person_add_sharp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
