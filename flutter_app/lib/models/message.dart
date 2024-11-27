import 'dart:convert';
import 'dart:developer' as devtools show log;

class Message {
  String messageId;
  String senderId;
  String receiverId;
  String? content;
  DateTime timestamp;
  String? imageUrl;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    this.content,
    required this.timestamp,
    this.imageUrl,
  });

factory Message.fromJson(Map<String, dynamic> json) {
  devtools.log('Received message JSON: $json');

  String? content = json['content'];
  if (content != null && content.startsWith("{") && content.endsWith("}")) {
    try {
      final parsedContent = jsonDecode(content);  // Parse if it's a JSON string
      content = parsedContent['content']; // Extract the actual content
    } catch (e) {
      devtools.log('Error parsing content JSON: $e');
      content = 'Invalid content format';
    }
  }
  devtools.log("hey");
  return Message(
    messageId: json['message_id'],
    senderId: json['sender_id'],
    receiverId: json['receiver_id'],
    content: content,
    timestamp: DateTime.parse(json['timestamp']),
    imageUrl: json['imageUrl'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}
