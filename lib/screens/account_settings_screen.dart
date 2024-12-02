import 'package:app_settings/app_settings.dart';
import 'package:assumemate/api/firebase_api.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/screens/user_auth/change_password_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String? clientID = dotenv.env['PAYPAL_CLIENT_ID'];
final String? secretKey = dotenv.env['PAYPAL_CLIENT_SECRET'];

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with WidgetsBindingObserver {
  final ApiService apiService = ApiService();
  final FirebaseApi firebaseApi = FirebaseApi();
  final SecureStorage secureStorage = SecureStorage();
  final subtitleStyle = GoogleFonts.poppins();

  bool notifEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has returned to the foreground
      setNotificationPreference(); // Reload notification preferences
    } else if (state == AppLifecycleState.detached) {
      setNotificationPreference();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final notifStatus =
        await FirebaseMessaging.instance.getNotificationSettings();

    setState(() {
      notifEnabled =
          notifStatus.authorizationStatus == AuthorizationStatus.authorized;
    });

    prefs.setBool('push_notifications', notifEnabled);
  }

  Future<void> setNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();

    // Optimistically update UI
    try {
      final notifStatus =
          await FirebaseMessaging.instance.getNotificationSettings();

      final notifChanged =
          notifStatus.authorizationStatus == AuthorizationStatus.authorized;

      print('notifEnabled');
      print(notifEnabled);
      print(notifChanged);

      if (notifEnabled != notifChanged) {
        setState(() {
          notifEnabled = notifChanged;
        });

        await prefs.setBool('push_notifications', notifEnabled);

        if (!notifEnabled) {
          // If notifications are disabled, remove the FCM token from the server and locally
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            await apiService.removeFcmToken(token);
            await FirebaseMessaging.instance.deleteToken();
          }
          print('FCM Token removed due to disabled notifications');
        } else {
          // If notifications are enabled, get and save the FCM token
          final token = await FirebaseMessaging.instance.getToken();

          if (token == null || token.isEmpty) {
            // If token retrieval fails, revert UI and show error
            setState(() {
              notifEnabled = false;
            });
            await prefs.setBool('push_notifications', false);
            popUp(context, "Failed to retrieve notification token.");
            return;
          }

          // Save the token to the server
          await apiService.saveFcmToken(token);
          print('FCM Token saved successfully');
        }
      }
    } catch (e) {
      print("Error handling notification preference: $e");
      popUp(context, "An error occurred. Please try again.");

      // Revert UI on error
      setState(() {
        notifEnabled = !notifEnabled;
      });
      await prefs.setBool('push_notifications', !notifEnabled);
    }
  }

  Future<void> deact() async {
    try {
      final response = await apiService.deactivate();

      if (response.containsKey('success')) {
        await apiService.sessionExpired();
        await GoogleSignInApi.logout();
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
                    text:
                        notifEnabled ? descriptionEnabled : descriptionDisabled,
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
          IconButton(
            onPressed: () async {
              await AppSettings.openAppSettings(
                  type: AppSettingsType.notification);
            },
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 28,
            color: const Color(0xFF4A8AF0),
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
