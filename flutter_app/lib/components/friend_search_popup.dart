import 'package:flutter/material.dart';

class FriendSearchPopup extends StatefulWidget {
  const FriendSearchPopup({super.key});

  @override
  State<FriendSearchPopup> createState() => _FriendSearchPopupState();
}

class _FriendSearchPopupState extends State<FriendSearchPopup> {
  late TextEditingController _controller;

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
                        hintText: 'Type the name of other people'),
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
