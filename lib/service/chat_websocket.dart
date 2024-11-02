import 'dart:ffi';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final WebSocketChannel channel;

  WebSocketService(Int userId)
      : channel = WebSocketChannel.connect(
            Uri.parse('ws://your-server-address/chat/$userId/'));

  // Send message to the server
  void sendMessage(String message) {
    channel.sink.add(message);
  }

  // Close WebSocket connection
  void dispose() {
    channel.sink.close();
  }
}
