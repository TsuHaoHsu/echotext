import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as devtools show log;

Future<List<Map<String, dynamic>>> getMessages(
  String senderId,
  String receiverId,
  int skip,
  int limit,
) async {
  try {
    // Construct the URI
    final uri = Uri.parse(
        '${uriHTTP}get-message/?sender_id=$senderId&receiver_id=$receiverId&skip=$skip&limit=$limit');
    devtools.log("Making request to: $uri");

    // Send the HTTP GET request
    final response = await http.get(uri);
    devtools.log("Response received with status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      // Decode the JSON response
      final data = json.decode(response.body);
      devtools.log("Response data in get messages: $data");

      // Directly handle the list response
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception("Invalid response structure: $data");
      }
    } else {
      throw Exception(
          'Failed to load messages. Status code: ${response.statusCode}');
    }
  } catch (e) {
    devtools.log('Error in getMessages: $e');
    rethrow;
  }
}