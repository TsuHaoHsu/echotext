import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<bool> deleteFriend(
  String friendshipId
) async {
  try {
    final response = await http.delete(
      Uri.parse("${uriHTTP}remove-friend/$friendshipId"),
      headers: <String,String>{
        'Content-Type': 'application/json'
      }
    );
    if (response.statusCode == 200){
      devtools.log('Deletion success');
      return true;
    } else 
      {devtools.log('Deletion failed with status: ${response.statusCode}, body: ${response.body}');
      return false;
    }
  } catch (e) {
    rethrow;
  }
}