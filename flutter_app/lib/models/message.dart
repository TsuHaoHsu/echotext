class Message {
  String senderId;
  String receiverId;
  String? content;
  String? imageUrl;
  DateTime timestamp;

  Message({
    required this.senderId,
    required this.receiverId,
    this.content,
    this.imageUrl,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json){
    return Message(
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }

}
