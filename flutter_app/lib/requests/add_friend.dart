import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<bool> addFriend(
  String userId,
  String userId2,
) async {
  try {
    final response = await http.post(
      Uri.parse("${uri}friend-request/"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, String>{
          'user1_id': userId,
          'user2_id': userId2,
        },
      ),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final status = userData['status'];
      final userRequest = userData['receiver'];

      if (status == 'pending') {
        devtools.log('Friend request sent to $userRequest');
        return true;
      } else {
        devtools.log('Friend request canceled');
        return false;
      }
    } else {
      throw Exception('Failed to send friend request');
    }
  } catch (e) {
    rethrow;
  }
}
