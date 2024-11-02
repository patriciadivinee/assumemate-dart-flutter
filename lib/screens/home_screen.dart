import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/screens/feed_screen.dart';
import 'package:assumemate/screens/chat_screen.dart';
import 'package:assumemate/screens/highlighted_item_screen.dart';
import 'package:assumemate/screens/notification_screen.dart';
import 'package:assumemate/screens/profile_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? user;
  String? token;

  final SecureStorage secureStorage = SecureStorage();

  @override
  void initState() {
    _getUserType();
    _getUserToken();
    super.initState();
  }

  Future<void> _getUserType() async {
    String? userType = await secureStorage.getUserType();

    setState(() {
      user = userType;
    });
  }

  Future<void> _getUserToken() async {
    String? userToken = await secureStorage.getToken();

    setState(() {
      token = userToken;
    });
  }

  List<GButton> _buildTabs(int index) {
    return [
      GButton(
          icon: (index == 0) ? Icons.home : Icons.home_outlined, iconSize: 30),
      GButton(
          icon: (index == 1) ? Icons.star : Icons.star_outline_outlined,
          iconSize: 30),
      GButton(
          icon:
              (index == 2) ? Icons.notifications : Icons.notifications_outlined,
          iconSize: 30),
      GButton(
          icon: (index == 3) ? Icons.messenger : Icons.messenger_outline,
          iconSize: 30),
      GButton(
          icon: (index == 4) ? Icons.person : Icons.person_outline,
          iconSize: 30),
    ];
  }

  Widget _buildContent(index) {
    switch (index) {
      case 0:
        return const FeedScreen();
      case 1:
        return const HighlightedItemScreen();
      case 2:
        return const NotificationScreen();
      case 3:
        return const ChatScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const FeedScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: LoadingAnimation(),
      );
    }

    return Scaffold(
      body: _buildContent(_selectedIndex),
      bottomNavigationBar: Container(
        color: const Color(0xff4A8AF0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          child: GNav(
              backgroundColor: const Color(0xff4A8AF0),
              color: const Color(0xffFFFCF1),
              activeColor: const Color(0xffFFFCF1),
              // tabBackgroundColor: const Color(0xffFFFCF1),

              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              rippleColor: Colors.transparent,
              iconSize: 26,
              duration: const Duration(milliseconds: 200),
              tabs: _buildTabs(_selectedIndex),
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              }),
        ),
      ),
    );
  }
}
