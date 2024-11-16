import 'package:echotext/models/message.dart';
import 'package:echotext/requests/fetch_message_stream.dart';
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
  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    // load message
    _webSocketService = WebSocketService(UserService.userId!, widget.contactId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _webSocketService.closeConnection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
      ),
      body: Column(
        children: [
          StreamBuilder(
            stream: _webSocketService.messages,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading messages'));
              }
              if (!snapshot.hasData || snapshot.data!['message'] == null) {
                return const Center(child: Text('No message yet'));
              }
              // Check if the data is a List of Map<String, dynamic>
              final rawMessages = snapshot.data;
              List<Message> messages = [];

              // If it's indeed a List<Map<String, dynamic>>, map each entry to a Message
              if (rawMessages is List) {
                messages = rawMessages.map((msg) {
                  if (msg is Map<String, dynamic>) {
                    return Message.fromJson(msg); // Convert to Message
                  } else {
                    return Message(
                      messageId: '',
                      senderId: '',
                      receiverId: '',
                      timestamp: DateTime.now(),
                    ); // Handle the invalid type gracefully
                  }
                }).toList();
              } else {
                devtools.log('Expected a List but got: $rawMessages');
              }

              return Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isSentByMe = message.senderId == UserService.userId;

                    return Align(
                      alignment: isSentByMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ListTile(
                          title: message.content != null
                              ? message.content!.startsWith('http')
                                  ? Image.network(
                                      message.content!,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    )
                                  : Text(message.content!)
                              : const Text('No content'),
                          subtitle: Text(message.timestamp.toString()),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
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
                //send message
                String message = _textController.text;

                if (message.isNotEmpty) {
                  _textController.clear();
                }
              },
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
