import 'package:assumemate/api/firebase_api.dart';
import 'package:assumemate/service/service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/screens/feed_screen.dart';
import 'package:assumemate/screens/chat_screen.dart';
import 'package:assumemate/screens/highlighted_item_screen.dart';
import 'package:assumemate/screens/notification_screen.dart';
import 'package:assumemate/screens/profile_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApiService apiService = ApiService();
  int _selectedIndex = 0;
  String? user;
  String? token;

  final SecureStorage secureStorage = SecureStorage();

  @override
  void initState() {
    getNotifPermission();
    _getUserToken();
    super.initState();
  }

  Future<void> getNotifPermission() async {
    // Save FCM token after login
    final prefs = await SharedPreferences.getInstance();
    print('push_notifications');
    print(prefs.getBool('push_notifications'));
    final FirebaseApi firebaseApi = FirebaseApi();
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      // Send FCM token to the backend for saving
      final notifStatus =
          await FirebaseMessaging.instance.getNotificationSettings();

      if (notifStatus.authorizationStatus != AuthorizationStatus.authorized &&
          prefs.getBool('push_notifications') == null) {
        final isEnabled = await firebaseApi.requestNotificationPermission();

        if (isEnabled) {
          await apiService.saveFcmToken(fcmToken);
          // prefs.setBool('push_notifications', true);
        } else {
          // await apiService.removeFcmToken(fcmToken);
          await FirebaseMessaging.instance.deleteToken();
          // prefs.setBool('push_notifications', false);
        }
      }
    }
  }

  Future<void> _getUserToken() async {
    String? userToken = await secureStorage.getToken();
    String? userType = await secureStorage.getUserType();

    setState(() {
      token = userToken;
      user = userType;
    });
  }

  List<GButton> _buildTabs(int index) {
    return [
      GButton(
          icon: (index == 0) ? Icons.home_rounded : Icons.home_outlined,
          iconSize: 30),
      GButton(
          icon: (index == 1) ? Icons.star_rounded : Icons.star_outline_rounded,
          iconSize: 30),
      GButton(
          icon: (index == 2)
              ? Icons.notifications_rounded
              : Icons.notifications_outlined,
          iconSize: 30),
      GButton(
          icon: (index == 3)
              ? Icons.messenger_rounded
              : Icons.messenger_outline_rounded,
          iconSize: 30),
      GButton(
          icon: (index == 4)
              ? Icons.person_rounded
              : Icons.person_outline_rounded,
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
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 18),
          child: GNav(
              backgroundColor: const Color(0xff4A8AF0),
              color: const Color(0xffFFFCF1),
              activeColor: const Color(0xffFFFCF1),
              // tabBackgroundColor: const Color(0xffFFFCF1),

              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              rippleColor: const Color(0xff4A8AF0).withOpacity(.8),
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
