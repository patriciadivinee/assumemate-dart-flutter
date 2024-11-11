import 'package:assumemate/screens/other_profile_screen.dart';
import 'package:flutter/material.dart';

class FollowScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> follow;
  const FollowScreen({super.key, required this.title, required this.follow});

  @override
  State<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends State<FollowScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xffFFFCF1),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
        child: widget.follow.isEmpty
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied,
                          size: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'There\'s nothing here',
                        )
                      ],
                    ),
                  ])
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.follow.length,
                itemBuilder: (context, index) {
                  final follow = widget.follow[index];
                  return InkWell(
                      onTap: () {
                        setState(() {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => OtherProfileScreen(
                                    userId: follow['user_id'].toString(),
                                  )));
                        });
                      },
                      child: ListTile(
                        tileColor: const Color(0xffFFFCF1),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 7),
                        minTileHeight: 60,
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(follow['profile']),
                        ),
                        title: Text(
                          follow['fullname'],
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ));
                }),
      ),
    );
  }
}
