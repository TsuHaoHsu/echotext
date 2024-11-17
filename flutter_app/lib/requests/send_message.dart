import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<void> sendMessage(
  final String senderId,
  final String receiverId,
  final String content,
) async {
  final response = await http.post(Uri.parse('${uriHTTP}create-message/'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, String>{
          'sender_id': senderId,
          'receiver_id': receiverId,
          'content': content,
        },
      ));
  if (response.statusCode == 200) {
    final messageData = json.decode(response.body);
    devtools.log('message created with id ${messageData['message_id']}');
  } else {
    devtools.log('message failed');
  }
}
