import 'package:echotext/components/dialog_popup.dart';
import 'package:echotext/requests/add_friend.dart';
import 'package:echotext/requests/delete_friend.dart';
import 'package:echotext/requests/get_pending_request.dart';
import 'package:echotext/services/user_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class ContactPopup extends StatefulWidget {
  final String userId;
  final String userName;
  final String profilePicture;

  const ContactPopup({
    super.key,
    required this.userName,
    required this.profilePicture,
    required this.userId,
  });

  @override
  State<ContactPopup> createState() => _ContactPopupState();
}

class _ContactPopupState extends State<ContactPopup> {
  late TextEditingController _controller;
  late String name = widget.userName;
  late String pic = widget.profilePicture;
  late String userId = widget.userId;
  late String currentUserId = UserService.userId!;
  String _buttonText = 'Send Request';
  IconData _buttonIcon = Icons.person_add_sharp;
  late String _friendShipId;
  bool _isButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _checkRelationShipStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onButtonPressed() async {
    if (!_isButtonEnabled) return;

    setState(() {
      _isButtonEnabled = false;
    });

    try {
      //devtools.log("Friend request from ${UserService.userId!} to ${widget.userId}");
      if (_buttonText == 'Add friend' ||
          _buttonText == 'Cancel friend request') {
        String response = await addFriend(UserService.userId!, widget.userId);
        //devtools.log(response);

        if (!context.mounted) return;
        if (response == 'Sent') {
          // Friend request sent
          if (!context.mounted) return;
          dialogPopup(
            context,
            "Success",
            "Friend request sent",
          );

        await _checkRelationShipStatus(); // Recheck after removal
        } else if (response == 'Canceled') {
          // Friend request canceled
          if (!context.mounted) return;
          dialogPopup(
            context,
            "Success",
            "Friend request canceled",
          );
        await _checkRelationShipStatus(); // Recheck after removal
      } else if (_buttonText == 'Remove friend') {
        await deleteFriend(_friendShipId);
        await _checkRelationShipStatus(); // Recheck after removal
      }

    }} catch (e) {
      if (!context.mounted) return;
      dialogPopup(context, 'Error', '$e');
    } finally {
      // Set a delay before re-enabling the button
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isButtonEnabled = true;
        });
      });
    }
  }

  Future<void> _checkRelationShipStatus() async {
    if (UserService.userId != null) {
      // refresh friendlist everytime you pull up a profile
      //await UserService.fetchFriendList();

      // Check for pending requests and friendship
      final Map<String, dynamic>? friend = UserService.friendList?.firstWhere(
        (friend) => friend['user_id'] == userId,
        orElse: () =>
            <String, dynamic>{}, // return null as default if not found
      );

      bool isFriend = friend!.isNotEmpty;
      Map<String, dynamic> pendingRequest = await getPendingRequest(currentUserId, widget.userId);
      String isPending = pendingRequest['message'] ?? 'no pending request';
      //devtools.log("The responses are $isFriend and $isPending");
      setState(() {
        if (isFriend) {
          _friendShipId = friend['friendship_id'];
          _buttonIcon = Icons.person_remove_sharp;
          _buttonText = 'Remove friend';
          devtools.log("Friendship ID: ${friend['friendship_id']}");
        } else if (isPending == 'pending') {
          if(pendingRequest['sender_id'] == currentUserId){
            _buttonIcon = Icons.person_add_disabled_outlined;
            _buttonText = 'Cancel friend request';
          }else{
            _buttonIcon = Icons.more_horiz;
            _buttonText = 'Manage friend request';
          }
        } else {
          _buttonText = 'Add friend';
          _buttonIcon = Icons.person_add_alt_1_outlined;
        }
      });
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
              Visibility(
                visible: userId != currentUserId,
                child: IconButton(
                  onPressed: _isButtonEnabled ? _onButtonPressed : null,
                  icon: Icon(_buttonIcon),
                  tooltip: _buttonText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
