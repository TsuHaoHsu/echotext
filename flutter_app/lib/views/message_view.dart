import 'package:echotext/models/message.dart';
import 'package:echotext/requests/fetch_message_stream.dart';
import 'package:echotext/requests/send_message.dart';
import 'package:echotext/services/timestamp_service.dart';
import 'package:echotext/services/user_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class MessageView extends StatefulWidget {
  final String contactId;
  final String contactName;
  const MessageView({
    super.key,
    required this.contactId,
    required this.contactName,
  });

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late WebSocketService _webSocketService;

  late String currentUserId = UserService.userId!;
  late String contactId = widget.contactId;

  List<Message> messages = []; // List to store messages
  bool isLoadingMore = false;
  bool hasMoreMessages = true; // Assume more messages initially
  int skip = 0; // Tracks how many messages have been loaded
  int limit = 20; // Number of messages per batch

  @override
  void initState() {
    super.initState();
    // load message
    _webSocketService = WebSocketService(currentUserId, contactId);

    // Listen for incoming WebSocket messages
    _listenForMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _webSocketService.closeConnection();
    super.dispose();
  }

void _listenForMessages() {
  _webSocketService.messages.listen((data) {
    devtools.log('Received data: $data');

    // Handle new message
    if (data.containsKey('new_message')) {
      var newMessage = data['new_message'];
      if (newMessage is Map) {
        devtools.log('Single new message received: $newMessage');
        // Wrap the new message in a list
        List<dynamic> messageList = [newMessage];

        // Process the list of new messages
        List<Message> newMessages = messageList.map((messageJson) {
          return Message.fromJson(messageJson);
        }).toList();

        setState(() {
          messages.insertAll(0, newMessages);  // Insert new messages at the top
        });
      } else {
        devtools.log('Unexpected format for new_message: ${newMessage.runtimeType}');
      }
    }

    // Handle old messages (if any)
    if (data.containsKey('message')) {
      var oldMessage = data['message'];
      if (oldMessage is List) {
        devtools.log('Old message received: $oldMessage');
        // Process the old messages
        List<Message> oldMessagesList = oldMessage.map((messageJson) {
          return Message.fromJson(messageJson);
        }).toList();

        setState(() {
          messages.addAll(oldMessagesList);  // Add old messages at the bottom
        });
      } else {
        devtools.log('Unexpected format for message: ${oldMessage.runtimeType}');
      }
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('No messages yet'),
                  )
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      bool isSentByMe = message.senderId == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Align(
                          alignment: isSentByMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                              crossAxisAlignment: isSentByMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                message.content != null
                                    ? message.content!.startsWith('http')
                                        ? Image.network(
                                            message.content!,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(Icons.error);
                                            },
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: isSentByMe
                                                  ? Colors.orange[100]
                                                  : Colors.grey[400],
                                              borderRadius: BorderRadius.circular(
                                                  8.0), // Optional: Rounded corners
                                            ),
                                            child: Text(message.content!,
                                                textAlign: isSentByMe
                                                    ? TextAlign.end
                                                    : TextAlign.start),
                                          )
                                    : const Text('No content'),
                                Text(formatTimestamp(message.timestamp),
                                    style: const TextStyle(fontSize: 11.0),
                                    textAlign: isSentByMe
                                        ? TextAlign.end
                                        : TextAlign.start),
                              ]),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder()),
              ),
            ),
            IconButton(
              onPressed: () {
                final content = _textController.text.trim();
                sendMessage(currentUserId, contactId, content);
              },
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
