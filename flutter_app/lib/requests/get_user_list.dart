import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
//import 'dart:developer' as devtools show log;

Future<List<Map<String, dynamic>>> getUserList(String searchQuery) async {
  final response = await http.get(
    Uri.parse("${uri}user-list/?query=$searchQuery"),
    headers: <String, String>{'Content-Type': 'application/json'},
  );
  if (response.statusCode == 200) {
    try {
      //devtools.log("Response body: ${response.body}");
      final List<dynamic> data = jsonDecode(response.body);
      
      // Convert the dynamic list to a List<Map<String, dynamic>> explicitly
      return data.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
      
    } catch (e) {
      throw Exception('Failed to parse friend list data: $e');
    }
  } else {
    throw Exception(
        'Failed to load user list, status code: ${response.statusCode}');
  }
}
