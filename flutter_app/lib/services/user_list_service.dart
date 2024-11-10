import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> getUserList() async {
  final response = await http.get(
    Uri.parse("${uri}user_list/"),
    headers: <String, String>{'Content-Type': 'application/json'},
  );
  if (response.statusCode == 200) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['name'] != null && data['name'] is List) {

        return List<Map<String, dynamic>>.from(data['name']);

      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to parse friend list data: $e');
    }
  } else {
    throw Exception('Failed to load user list, status code: ${response.statusCode}');
  }
}
