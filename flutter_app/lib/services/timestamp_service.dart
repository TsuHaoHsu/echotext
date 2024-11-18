import 'package:intl/intl.dart';

String formatTimestamp(DateTime timestamp){
  final now = DateTime.now();
  final currentDate = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

  final difference = currentDate.difference(messageDate).inDays;

  if (difference == 1){
    return 'Yesterday at ${DateFormat.jm().format(timestamp)}'; // eg. 5:30pm
  } else if (difference == 0){
    return 'Today at ${DateFormat.jm().format(timestamp)}'; // eg. Yesterday at 5:30pm
  } else {
    return DateFormat('yMMMMd').add_jm().format(timestamp); // e.g., November 17, 2024 at 5:30 PM
  }
}