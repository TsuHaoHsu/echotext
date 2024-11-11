import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:http/http.dart' as http;

Future<String> getFriendship(
  String a,
) async {
  final response = await http.get(
    Uri.parse('${uri}relationship')
  );
}