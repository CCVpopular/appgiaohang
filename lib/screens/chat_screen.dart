import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import '../config/config.dart';
import '../widgets/incoming_call_dialog.dart';
import '../screens/call_screen.dart';

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
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initializeSocket();
    _setupCallHandlers();
  }

  void _setupCallHandlers() {
    // Listen for incoming calls
    socket.on('call-to-${widget.currentUserId}', (data) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => IncomingCallDialog(
          callerName: data['callerName'],
          onAccept: () {
            Navigator.pop(context);
            // Notify caller that call was accepted
            socket.emit('call-accepted', {
              'callerId': data['callerId'],
              'channelName': data['channelName']
            });
            // Join the call
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallScreen(
                  channelName: data['channelName'],
                  token: data['token'],
                  isOutgoing: false,
                ),
              ),
            );
          },
          onDecline: () {
            socket.emit('call-rejected', {
              'callerId': data['callerId']
            });
            Navigator.pop(context);
          },
        ),
      );
    });

    // Listen for call accepted
    socket.on('call-accepted-${widget.currentUserId}', (data) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call was accepted')),
      );
    });

    // Listen for call rejected
    socket.on('call-rejected-${widget.currentUserId}', (data) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call was declined')),
      );
    });

    // Listen for call ended
    socket.on('call-ended-${widget.currentUserId}', (data) {
      Navigator.of(context).pop(); // Close call screen
    });
  }

  void _initializeSocket() {
    socket = IO.io(Config.baseurl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.emit('join-chat', widget.orderId);

    socket.on('message-received', (data) {
      if (mounted) {
        setState(() {
          final messageData = Map<String, dynamic>.from(data);
          messageData['sender_id'] = data['senderId']; // Thêm dòng này
          messages.add(messageData);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseurl}/chat/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = {
      'orderId': widget.orderId,
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'message': _messageController.text.trim(),
      'sender_id': widget.currentUserId,
      'sender_name': 'You',
    };

    try {
      final response = await http.post(
        Uri.parse('${Config.baseurl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message),
      );

      if (response.statusCode == 201) {
        socket.emit('new-message', message);
        _messageController.clear();
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _initiateCall() async {
    final token = 'YOUR_AGORA_TOKEN'; // Replace with actual token
    final channelName = 'call_${widget.orderId}';

    socket.emit('initiate-call', {
      'receiverId': widget.otherUserId,
      'callerId': widget.currentUserId,
      'callerName': 'You', // Replace with actual user name
      'channelName': channelName,
      'token': token,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          token: token,
          isOutgoing: true,
          onCallEnded: () {
            socket.emit('end-call', {
              'receiverId': widget.otherUserId,
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherUserName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: _initiateCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['sender_id'] == widget.currentUserId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['sender_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(message['message']),
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
}
