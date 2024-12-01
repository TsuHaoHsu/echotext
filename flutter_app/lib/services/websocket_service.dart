import 'dart:async';
import 'dart:convert';
import 'package:echotext/constants/uri.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:developer' as devtools show log;

class WebSocketService {
  final WebSocketChannel channel;
  final StreamController<dynamic> _controller = StreamController.broadcast();

  WebSocketService(String senderId, String receiverId)
      : channel = WebSocketChannel.connect(
          Uri.parse('${uriWS}ws/messages/$senderId/$receiverId'),
        ) {
    channel.stream.listen(
      (event) {
        devtools.log(
            "Raw WebSocket data: $event"); // Log the raw event before decoding
        try {
          final data = json.decode(event);
          devtools.log("Decoded WebSocket data: $data");

          // Check for both 'message' and 'new_message' keys
          if (data.containsKey("message")) {
            final newMessages = data["message"];
            if (newMessages is List) {
              devtools.log("Messages: $newMessages");
              _controller.add(
                  newMessages); // Send all messages directly to the controller
            } else if (newMessages is Map<String, dynamic>) {
              devtools.log("Single message: $newMessages");
              _controller.add([newMessages]); // Wrap single message in a list
            }
          } else if (data.containsKey("new_message")) {
            final newMessage = data["new_message"];
            if (newMessage is Map<String, dynamic>) {
              devtools.log("New message: $newMessage");
              _controller
                  .add([newMessage]); // Wrap single new message in a list
            }
          }
        } catch (e) {
          devtools.log("Error decoding WebSocket message: $e");
        }
      },
      onError: (error) {
        devtools.log("WebSocket error: $error");
      },
      onDone: () {
        devtools.log("WebSocket connection closed.");
      },
    );
    devtools.log('WebSocket connected for $senderId and $receiverId');
  } // Ensure the stream is of type Stream<List<dynamic>>
  Stream<List<dynamic>> get messages =>
      _controller.stream.map((data) => data as List<dynamic>);

  void sendMessage(
      {required String senderId, required String receiverId, String? content}) {
    final message = {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    };
    devtools.log('Sending message: $message');
    channel.sink.add(json.encode(message));
  }

  void closeConnection() {
    _controller.close();
    channel.sink.close();
  }
}
