import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;

Future<Map<String,dynamic>> getPendingRequest(
  String senderId,
  String receiverId,
) async {
  final response = await http.get(
    Uri.parse('${uri}request-query/?sender_id=$senderId&receiver_id=$receiverId'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
  );
  if(response.statusCode == 200){

    final result = jsonDecode(response.body);
    
    if(result['message'].isNotEmpty){
      return result;
    }
    else {
      return {};
    }

  } else {
    throw Exception(
        'Failed to load user request status, status code: ${response.statusCode}');
  }
}