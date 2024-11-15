import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<bool> deleteFriendRequest(
  String senderId,
  String receiverId,
) async {
  try {
    final response =
        await http.delete(Uri.parse("${uri}reject-friend-request/"),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode({
              'sender_id': senderId,
              'receiver_id': receiverId,
            }));
    if (response.statusCode == 200) {
      devtools.log('Deletion success');
      return true;
    } else {
      devtools.log(
          'Deletion failed with status: ${response.statusCode}, body: ${response.body}');
      return false;
    }
  } catch (e) {
    devtools.log('Deletion error: $e');
    rethrow;
  }
}
