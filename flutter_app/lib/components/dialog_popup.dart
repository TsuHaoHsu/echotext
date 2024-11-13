import 'package:echotext/models/dialog.dart';
import 'package:flutter/material.dart';

Future<void> dialogPopup(
  BuildContext context,
  String title,
  String content, {
  VoidCallback? onAccept, // Optional accept callback
  VoidCallback? onReject, // Optional reject callback
}) {
    return showDialog(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        title: title,
        content: content,
        onAccept: onAccept,
        onReject: onReject,
      );
    },
  );
}
