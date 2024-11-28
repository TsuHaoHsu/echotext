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
              // Filter messages by sender and receiver IDs
              final filteredMessages = newMessages.where((msg) {
                return (msg['sender_id'] == senderId &&
                        msg['receiver_id'] == receiverId) ||
                    (msg['sender_id'] == receiverId &&
                        msg['receiver_id'] == senderId);
              }).toList();

              devtools.log("Filtered messages: $filteredMessages");
              if (filteredMessages.isNotEmpty) {
                _controller.add(filteredMessages);
              }
            } else if (newMessages is Map<String, dynamic>) {
              // Single message scenario, validate sender and receiver
              if ((newMessages['sender_id'] == senderId &&
                      newMessages['receiver_id'] == receiverId) ||
                  (newMessages['sender_id'] == receiverId &&
                      newMessages['receiver_id'] == senderId)) {
                devtools.log("Filtered single message: $newMessages");
                _controller.add([newMessages]); // Wrap single message in a list
              }
            }
          } else if (data.containsKey("new_message")) {
            final newMessage = data["new_message"];
            if (newMessage is Map<String, dynamic>) {
              // Handle single new message and filter
              if ((newMessage['sender_id'] == senderId &&
                      newMessage['receiver_id'] == receiverId) ||
                  (newMessage['sender_id'] == receiverId &&
                      newMessage['receiver_id'] == senderId)) {
                devtools.log("Filtered new message: $newMessage");
                _controller.add([newMessage]); // Wrap single message in a list
              }}}
            // } else if (newMessage is List) {
            //   // Handle multiple new messages and filter
            //   final filteredNewMessages = newMessage.where((msg) {
            //     return (msg['sender_id'] == senderId &&
            //             msg['receiver_id'] == receiverId) ||
            //         (msg['sender_id'] == receiverId &&
            //             msg['receiver_id'] == senderId);
            //   }).toList();

            //   devtools.log("Filtered new messages: $filteredNewMessages");
            //   if (filteredNewMessages.isNotEmpty) {
            //     _controller.add(filteredNewMessages);
            //   }
            
          
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
