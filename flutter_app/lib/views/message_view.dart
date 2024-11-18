import 'package:echotext/models/message.dart';
import 'package:echotext/requests/fetch_message_stream.dart';
import 'package:echotext/requests/get_messages.dart';
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

    _loadMessages();

    // Listen for incoming WebSocket messages
    _listenForMessages();

    // Add a scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          hasMoreMessages &&
          !isLoadingMore) {
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _webSocketService.closeConnection();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });
    try {
      
      final newMessages =
          await getMessages(currentUserId, contactId, skip, limit);
      setState(() {
        // Convert each item in newMessages to a Message object
        List<Message> newMessagesObjects = newMessages.map((messageJson) {
          return Message.fromJson(messageJson);
        }).toList();
        
        // Insert the converted messages at the start of the list (reverse the order)
        messages.insertAll(
            0, newMessagesObjects.reversed); // Add at the beginning of the list
        skip += newMessagesObjects.length; // Update skip for the next batch
        hasMoreMessages = newMessagesObjects.length ==
            limit; // Check if there are more messages to load
      });
    } catch (e) {
      devtools.log('Error loading messages: $e');
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
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
      List<dynamic> messageList =
          data['message'] ?? []; // Default to an empty list if null

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
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
