import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content, this.onAccept, this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        if (onReject != null) // Show Reject button if onReject is provided
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onReject?.call(); // Call reject action if provided
            },
            child: const Text("Reject"),
          ),
        if (onAccept != null) // Show Accept button if onAccept is provided
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAccept?.call(); // Call accept action if provided
            },
            child: const Text("Accept"),
          ),
        if (onAccept == null && onReject == null) // Show a single "Close" button if neither is provided
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
      ],
    );
  }
}
