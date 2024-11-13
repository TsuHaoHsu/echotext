import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;

Future<String> acceptFriendRequest(
  final String friendshipId,
) async {
  final response = await http.post(
    Uri.parse('${uri}accept_friend_request/'),
    headers: <String, String>{
      'Content-Type': 'application/json'
    },
    body: json.encode({
      'friendship_id': friendshipId,
    }),
  );
  if(response.statusCode == 200){
    return "Success";
  }else{
    return "Failed to accept";
  }
}