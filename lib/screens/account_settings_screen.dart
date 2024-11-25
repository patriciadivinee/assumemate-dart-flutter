import 'dart:convert';
import 'package:assumemate/api/firebase_api.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/screens/user_auth/change_password_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String? clientID = dotenv.env['PAYPAL_CLIENT_ID'];
final String? secretKey = dotenv.env['PAYPAL_CLIENT_SECRET'];

class AccontSettingsScreen extends StatefulWidget {
  const AccontSettingsScreen({super.key});

  @override
  State<AccontSettingsScreen> createState() => _AccontSettingsScreenState();
}

class _AccontSettingsScreenState extends State<AccontSettingsScreen> {
  final ApiService apiService = ApiService();
  final FirebaseApi firebaseApi = FirebaseApi();
  final SecureStorage secureStorage = SecureStorage();
  final subtitleStyle = GoogleFonts.poppins();

  Map<String, bool> toggleStates = {'push_notifications': true};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      toggleStates['push_notifications'] =
          prefs.getBool('push_notifications') ?? true;
    });
  }

  Future<void> setNotificationPreference(String type, bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (type == 'push_notifications') {
      if (value) {
        // Enable notifications
        await firebaseApi.requestNotificationPermission();
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          try {
            await apiService.saveFcmToken(token);
          } catch (e) {
            popUp(context, "Failed to enable notifications. Please try again.");
            return;
          }
        } else {
          popUp(context, "Failed to retrieve notification token.");
          return;
        }
      } else {
        // Disable notifications
        try {
          String? token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            await apiService.removeFcmToken(token);
            await FirebaseMessaging.instance.deleteToken();
          }
        } catch (e) {
          print("Error removing FCM token: $e");
        }
      }
    }

    // Save preferences and update the toggle state
    await prefs.setBool(type, value);
    setState(() {
      toggleStates[type] = value;
    });
  }

  Future<void> deact() async {
    try {
      final response = await apiService.deactivate();

      if (response.containsKey('success')) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occurred: $e');
    }
  }

  Widget buildToggleRow({
    required String title,
    required String descriptionEnabled,
    required String descriptionDisabled,
    required String preferenceKey,
    required IconData icon,
  }) {
    final isEnabled = toggleStates[preferenceKey] ?? true;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff4A8AF0), size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: subtitleStyle,
                children: <TextSpan>[
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: isEnabled ? descriptionEnabled : descriptionDisabled,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Make the Switch the only clickable element
          Switch(
            value: isEnabled,
            onChanged: (value) async {
              await setNotificationPreference(preferenceKey, value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? "Notification: On" : "Notification: Off",
                  ),
                  duration: const Duration(milliseconds: 100),
                ),
              );
            },
            activeColor: const Color(0xff4A8AF0),
            inactiveTrackColor: const Color(0xffFFFCF1),
            // inactiveThumbColor: const Color(0xff4A8AF0),
            // inactiveThumbColor: const Color(0xff4A8AF0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff4A8AF0),
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(Icons.arrow_back_ios),
          color: const Color(0xffFFFEF7),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Account Settings",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xffFFFEF7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildToggleRow(
                title: 'Push Notifications',
                descriptionEnabled: 'Notifications: On.',
                descriptionDisabled: 'Notifications: off.',
                preferenceKey: 'push_notifications',
                icon: Icons.notifications_outlined,
              ),
              InkWell(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xff4A8AF0),
                        size: 40,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: subtitleStyle,
                            children: const <TextSpan>[
                              TextSpan(
                                text: 'Account Information\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'See your account information like your email address, user type, and phone number',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outlined,
                        color: Color(0xff4A8AF0),
                        size: 36,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: subtitleStyle,
                            children: const <TextSpan>[
                              TextSpan(
                                text: 'Change your password\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: 'Change your password at anytime',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  showConfirmation(
                    context,
                    'Are you sure you want to deactivate your account?',
                    'Deactivating your account will prevent others from viewing your listings or making offers.',
                    () => deact(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff683131),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  "Deactivate",
                  style: TextStyle(
                    color: Color(0xffFFFEF7),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  await apiService.sessionExpired();
                  await GoogleSignInApi.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A8AF0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Color(0xffFFFEF7),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showConfirmation(
      BuildContext context, String title, String? desc, Function confirm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          contentPadding: const EdgeInsets.only(left: 18, right: 18, top: 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              if (desc != null)
                Text(
                  desc,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.start,
                )
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: Color(0xff4A8AF0), fontWeight: FontWeight.w400),
                  ),
                ),
                TextButton(
                  onPressed: () => confirm(),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                        color: Color(0xff4A8AF0), fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
