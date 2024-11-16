import 'dart:convert';

import 'package:echotext/constants/uri.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  final WebSocketChannel channel;

  WebSocketService(String senderId, String receiverId): channel = WebSocketChannel.connect(Uri.parse('${uriWS}ws/messages/$senderId/$receiverId'),);

  Stream<dynamic> get messages => channel.stream.map((event) => json.decode(event));

  void sendMessage(String content) {
    channel.sink.add(content);
  }

  void closeConnection() {
    channel.sink.close();
  }
}