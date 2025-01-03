import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class ChatScreen extends StatefulWidget {
  final int orderId;
  final int currentUserId;
  final int otherUserId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.orderId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket socket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _loadMessages();
  }

  void _connectSocket() {
    socket = IO.io(Config.baseurl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.connect();
    socket.emit('join-chat', widget.orderId);

    socket.on('message-received', (data) {
      setState(() {
        _messages.add(data);
      });
    });
  }

  Future<void> _loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/chat/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        final messages = json.decode(response.body);
        setState(() {
          _messages.addAll(List<Map<String, dynamic>>.from(messages));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = {
      'orderId': widget.orderId,
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'message': _messageController.text,
      'sender_name': 'You', // Will be replaced by actual name on receiver's end
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await http.post(
        Uri.parse('${Config.baseurl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message),
      );

      socket.emit('new-message', message);

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherUserName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['sender_id'] == widget.currentUserId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['message'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                message['sender_name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    _messageController.dispose();
    super.dispose();
  }
}
