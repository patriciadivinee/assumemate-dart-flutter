import 'package:flutter/material.dart';
import 'package:assumemate/components/following.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: const Color(0xffFFFCF1),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            mainAxisExtent: 300,
          ),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return const Following();
          },
          itemCount: 5,
        ),
      ),
    );
  }
}
