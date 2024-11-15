import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<String> addFriend(
  String userId,
  String userId2,
  String senderName,
) async {
  try {
    final response = await http.post(
      Uri.parse("${uri}friend-request/"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, String>{
          'sender_id': userId,
          'receiver_id': userId2,
          'name': senderName,
        },
      ),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final status = userData['status'];
      final userRequest = userData['receiver'];

      if (status == 'pending') {
        devtools.log('Friend request sent to $userRequest');
        return "Sent";
      } else {
        devtools.log('Friend request canceled');
        return "Canceled";
      }
    } else {
      throw Exception('Failed to send friend request');
    }
  } catch (e) {
    rethrow;
  }
}
