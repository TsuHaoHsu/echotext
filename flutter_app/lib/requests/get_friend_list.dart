
import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;


Future<List<Map<String,dynamic>>> getFriendList(
  String userId,
) async {
    final response = await http.get(
      Uri.parse("${uri}friend-list/?user_id=$userId"),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Check if 'friends' key exists and is not empty
      if (data['friends'] != null && data['friends'] is List && data['friends'].isNotEmpty) {
        List<Map<String, dynamic>> friendList = List<Map<String, dynamic>>.from(
          data['friends'].map((item) => {
            'user_id': item['user_id'],
            'name': item['name'],
          }),
        );
        return friendList;
      } else {
        // If 'friends' is null or empty, return an empty list
        return [];
      }
    } catch (e) {
      throw Exception('Failed to parse friend list data: $e');
    }
  } else {
    throw Exception('Failed to load friend list, status code: ${response.statusCode}');
  }
}