import 'package:echotext/models/message.dart';
import 'package:echotext/services/websocket_service.dart';
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

  // Function to handle incoming messages
  void _listenForMessages() {
    _webSocketService.messages.listen((List<dynamic> data) {
      devtools.log('Received new message(s): $data');

      try {
        // Process the incoming messages and add them to the list
        List<Message> newMessages = data.map((messageJson) {
          return Message.fromJson(messageJson);
        }).toList();

        // Update the UI with the new messages
        setState(() {
          // Add new messages only if they're not already in the list
          for (var newMessage in newMessages) {
            if (!messages.any((msg) => msg.messageId == newMessage.messageId)) {
              messages.insert(0, newMessage); // Insert at the top (reverse order)
            }
          }
        });

        // Scroll to the bottom when a new message arrives
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        devtools.log('Error processing new message: $e');
      }
    });
  }

@override
Widget build(BuildContext context) {
  // Listen for new messages from WebSocket
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // Scroll to the bottom when a new message is added
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: BottomAppBar(
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
                  if (content.isNotEmpty) {
                    _webSocketService.sendMessage(
                      senderId:
                          currentUserId, // Replace with the actual current user ID
                      receiverId: contactId, // Replace with the actual contact ID
                      content: content,
                    );
                    _textController
                        .clear(); // Clear the input field after sending
                  }
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
