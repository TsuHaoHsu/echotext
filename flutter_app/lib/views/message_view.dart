import 'package:echotext/models/message.dart';
import 'package:echotext/requests/fetch_message_stream.dart';
import 'package:echotext/requests/send_message.dart';
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
  late String currentUserId = UserService.userId!;
  late String contactId = widget.contactId;

  List<Message> messages = []; // List to store messages

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

  void _sendMessage() {
    final content = _textController.text.trim();

    if (content.isNotEmpty) {
      _textController.clear();

      // Disable input while waiting for server confirmation
      setState(() {
        messages.insert(
          0,
          Message(
            messageId: 'loading...', // Temporary placeholder
            senderId: currentUserId,
            receiverId: contactId,
            content: content,
            timestamp: DateTime.now(),
          ),
        );
      });

      // Send message via WebSocket
      _webSocketService.sendMessage(currentUserId, contactId, content);
    }
  }

void _listenForMessages() {
  _webSocketService.messages.listen((data) {
    // Check if 'message' is null or not a List
    List<dynamic> messageList = data['message'] ?? [];  // Default to an empty list if null

    if (messageList.isEmpty) {
      devtools.log('No new messages received.');
    } else {
      // Map each message to a Message object, handling the content properly
      List<Message> newMessages = messageList.map((messageJson) {
        return Message.fromJson(messageJson);
      }).toList();

      setState(() {
        messages.insertAll(0, newMessages);
      });
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
                                    : Text(message.content!,
                                        textAlign: isSentByMe
                                            ? TextAlign.end
                                            : TextAlign.start)
                                : const Text('No content'),
                            subtitle: Text(message.timestamp.toString(),
                                textAlign: isSentByMe
                                    ? TextAlign.end
                                    : TextAlign.start),
                          ),
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
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
