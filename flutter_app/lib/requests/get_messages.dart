import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:echotext/models/message.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<List<Message>> getMessages(
  final String senderId,
  final String receiverId,
) async {
  final response = await http.get(
    Uri.parse('${uriHTTP}get-message/?senderId=$senderId&receiverId=$receiverId'),
    headers: <String,String>{
      'Content-Type': 'application/json'
    },
  );
  if (response.statusCode == 200){
    
    final data = json.decode(response.body);
    List<Message> messages = (data['messages'] as List).map((messageJson) => Message.fromJson(messageJson)).toList();
    return messages;

  }
  else{
    return [];
  }
}