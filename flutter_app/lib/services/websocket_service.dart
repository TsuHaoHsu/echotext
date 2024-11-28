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
            // Ensure the data is a list of messages and add it to the stream
            if (newMessages is List) {
              _controller.add(newMessages); // Send list of messages
            } else {
              _controller.add(
                  [newMessages]); // Wrap single message in a list if needed
            }
          } else if (data.containsKey("new_message")) {
            final newMessage = data["new_message"];
            // Handle a single new message (could be a dictionary or object)
            if (newMessage is List) {
              _controller.add(newMessage); // Add the list of new messages
            } else {
              _controller
                  .add([newMessage]); // Wrap the single message in a list
            }
          }
        } catch (e) {
          devtools.log("Error decoding WebSocket event: $e");
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
