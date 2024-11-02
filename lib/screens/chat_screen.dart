import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:assumemate/components/chat_list.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _convos = [];

  final ApiService apiService = ApiService();
  final SecureStorage secureStorage = SecureStorage();
  WebSocketChannel? _inboxChannel;
  final String? baseURL = dotenv.env['WEB_SOCKET_URL'];

  String? _userId;

  Future<void> _getInbox() async {
    final token = await secureStorage.getToken();
    final response = await apiService.viewInbox(token!);

    if (response.containsKey('rooms')) {
      setState(() {
        _convos = List<Map<String, dynamic>>.from(response['rooms']);
      });
    }
  }

  Future<void> _initializeInboxWebsocket() async {
    _userId = await secureStorage.getUserId();
    final token = await secureStorage.getToken();
    if (_userId != null) {
      try {
        _inboxChannel = WebSocketChannel.connect(
          Uri.parse('$baseURL/ws/inbox/?token=$token'),
        );

        _inboxChannel!.stream.listen((message) {
          final messageResponse = jsonDecode(message);

          if (messageResponse['type'] == 'inbox_update') {
            setState(() {
              for (var msg in _convos) {
                if (msg['chatroom_id'] ==
                    int.parse(messageResponse['room_id'])) {
                  msg['mess_isread'] = messageResponse['isRead'];
                  msg['last_message'] = messageResponse['message'];
                  msg['last_message_date'] = messageResponse['timestamp'];
                  msg['sender_id'] = messageResponse['sender_id'];
                }
              }
            });
          } else if (messageResponse['type'] == 'inbox_read') {
            setState(() {
              for (var msg in _convos) {
                if (msg['chatroom_id'] ==
                    int.parse(messageResponse['room_id'])) {
                  msg['mess_isread'] = messageResponse['isRead'];
                }
              }
            });
          }
        });
      } catch (e) {
        popUp(context, 'Connection error: $e');
      }
    } else {
      popUp(context, 'User ID is null or empty');
    }
  }

  Future<void> initialization() async {
    await _getInbox();
    await _initializeInboxWebsocket();
  }

  @override
  void initState() {
    super.initState();
    initialization();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFFFCF1),
        title: const Text('Messages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xff4A8AF0)),
            iconSize: 26,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications icon pressed')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _getInbox,
          child: ListView.builder(
            itemCount: _convos.length,
            itemBuilder: (context, index) {
              final convo = _convos[index];
              return ChatList(
                id: convo['chatmate_id'].toString(),
                name: convo['chatmate_name'],
                msg: convo['last_message'],
                senderId: convo['sender_id'].toString(),
                time: convo['last_message_date'],
                profilePic: convo['chatmate_pic'],
                chatroomId: convo['chatroom_id'].toString(),
                isRead: convo['mess_isread'],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inboxChannel?.sink.close();
    super.dispose();
  }
}
