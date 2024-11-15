import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:echotext/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<String> acceptFriendRequest(
  final String receiverId,
  final String receiverName,
  final String senderId,
) async { 
  try{
  final response = await http.post(
    Uri.parse('${uri}accept-friend-request/'),
    headers: <String, String>{
      'Content-Type': 'application/json'
    },
    body: json.encode(<String,String>{
      'receiver_id': receiverId,
      'name': receiverName,
      'sender_id': senderId,
    }),
  );

  if(response.statusCode == 200){
    devtools.log("Accepted");
    await UserService.fetchFriendList();
    return "Success";
  }else{
    return "Failed to accept";
  }
  } catch (e) {
    rethrow;
  }
}
