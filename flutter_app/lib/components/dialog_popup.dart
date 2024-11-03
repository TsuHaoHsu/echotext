import 'package:echotext/models/error_dialog.dart';
import 'package:flutter/material.dart';

Future<void> dialogPopup(BuildContext context, String title, String content) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return ShowErrorDialog(title: title, content: content);
    },
  );
}