import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:assumemate/screens/chat_message_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';

class ChatList extends StatefulWidget {
  final String id;
  final String name;
  final String msg;
  final String senderId;
  final String time;
  final String profilePic;
  final String chatroomId;
  final bool isRead;

  const ChatList(
      {super.key,
      required this.id,
      required this.name,
      required this.msg,
      required this.senderId,
      required this.time,
      required this.profilePic,
      required this.chatroomId,
      required this.isRead});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late bool isread;
  String? userId;

  final ApiService apiService = ApiService();
  final SecureStorage secureStorage = SecureStorage();

  Future<void> _loadUserId() async {
    userId = await secureStorage.getUserId();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // isread = widget.isRead == 'true';
    _loadUserId();
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentdate = DateTime.now();
    DateTime dateTime = DateTime.parse(widget.time).toLocal();
    // String date = DateFormat('MMM dd yyyy').format(dateTime);
    // String time = DateFormat('hh:mm a').format(dateTime);
    String date;
    TextStyle timestyle = TextStyle(
        fontSize: 10,
        fontWeight: (widget.isRead || widget.senderId == userId)
            ? FontWeight.w500
            : FontWeight.bold);

    if (dateTime.year != currentdate.year) {
      date = DateFormat('MMM dd yyy').format(dateTime);
    } else if (dateTime.day == currentdate.day) {
      date = DateFormat('hh:mm a').format(dateTime);
    } else {
      date = DateFormat('MMM dd').format(dateTime);
    }

    return InkWell(
        onTap: () {
          setState(() {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatMessageScreen(
                      receiverId: widget.id,
                    )));
          });
        },
        child: ListTile(
            tileColor: const Color(0xffFFFCF1),
            leading:
                // Stack(
                //   children: [
                CircleAvatar(
              backgroundImage: widget.profilePic.isEmpty
                  ? NetworkImage(widget.profilePic)
                  : AssetImage('assets/images/no-profile.jpg'),
            ),
            //   const Positioned(
            //       right: 0,
            //       bottom: 0,
            //       child: CircleAvatar(
            //         radius: 5,
            //         backgroundColor: Colors.green,
            //       ))
            // ],
            // ),
            title: Text(
              widget.name,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: (widget.isRead || widget.senderId == userId)
                      ? FontWeight.w500
                      : FontWeight.bold),
            ),
            subtitle: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              (widget.senderId == userId) ? 'You: ${widget.msg}' : widget.msg,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: (widget.isRead || widget.senderId == userId)
                      ? FontWeight.w500
                      : FontWeight.bold),
            ),
            trailing: Text(
              date,
              style: timestyle,
            )));
  }
}
