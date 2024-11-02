import 'package:flutter/material.dart';
import 'package:assumemate/components/chat_list.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List name = ['Yushi', 'Sion', 'Ryo', 'Sakuya', 'Jaehee', 'Riku'];

  List isread = ['true', 'true', 'false', 'true', 'true', 'false'];

  List time = ['3:00', '2:35', '13:01', '20:23', '20:46', 'Fri'];

  List msgs = [
    'Ramen :>',
    'Yushi is mine!',
    'Wish for our wish',
    'dyudyudyu bababa',
    'I wanna be the best singer!! I wanna be the best singer!! I wanna be the best singer!! I wanna be the best singer!! I wanna be the best singer!! I wanna be the best singer!!',
    '나의 인생처럼 천천히~'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xffFFFCF1),
            title: const Text('Notifications',
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
            child: Column(
              children: [
                Container(
                  height: 15,
                  color: Colors.grey.shade300,
                ),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text(
                        "Earlier",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    child: ListView.builder(
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        return ChatList(
                          id: '1',
                          name: name[index],
                          msg: msgs[index],
                          senderId: '1',
                          time: time[index],
                          profilePic: isread[index],
                          chatroomId: '2',
                          isRead: false,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
