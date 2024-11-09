import 'package:flutter/material.dart';

class ContactPopup extends StatefulWidget {
  final String contactName;
  const ContactPopup({super.key, required this.contactName});

  @override
  State<ContactPopup> createState() => _ContactPopupState();
}

class _ContactPopupState extends State<ContactPopup> {
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage('https://imgur.com/OXA0Aej.jpg'),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration:
                      const InputDecoration(hintText: 'Enter Contact Name'),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
