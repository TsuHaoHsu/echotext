import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final WebSocketChannel channel;

  WebSocketService(String senderId, String receiverId)
      : channel = WebSocketChannel.connect(
          Uri.parse('${uriWS}ws/messages/$senderId/$receiverId'),
        );

  Stream<dynamic> get messages =>
      channel.stream.map((event) => json.decode(event));

  // void sendMessage(String content) {
  //   channel.sink.add(content);
  // }

  void sendMessage(String senderId, String receiverId, String content) {
    final message = json.encode({
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(), // Optional timestamp
    });

    channel.sink.add(message);
  }

  // Method to close the WebSocket connection
  void closeConnection() {
    channel.sink.close();
  }
}
