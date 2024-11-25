import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/provider/profile_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/screens/home_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:assumemate/api/firebase_api.dart';
import 'package:assumemate/service/service.dart';

class PendingApplicationScreen extends StatelessWidget {
  PendingApplicationScreen({super.key});

  final SecureStorage secureStorage = SecureStorage();
  final FirebaseApi firebaseApi = FirebaseApi();
  final ApiService apiService = ApiService();
  // get http => null;

  // void waitForVerification() {
  //   Timer.periodic(const Duration(seconds: 3), (timer) async {
  //     final String? baseURL = dotenv.env['API_URL'];
  //     final apiUrl = Uri.parse('$baseURL/check-user-verification/');
  //     final Map<String, dynamic> userEmail = {
  //       // 'user_verification_email': widget.email,
  //     };

  //     try {
  //       final response = await http.post(
  //         apiUrl,
  //         headers: {
  //           "Content-Type": "application/json",
  //         },
  //         body: jsonEncode(userEmail),
  //       );

  //       if (response.statusCode == 200) {
  //         if (response.statusCode == 200) {
  //           final data = jsonDecode(response.body);
  //           if (data['is_verified'] == true &&
  //               data['user_account_id'] == null) {
  //             timer.cancel(); // Stop polling
  //             navigatorKey.currentState?.pushReplacement(MaterialPageRoute(
  //               builder: (context) => const HomeScreen(),
  //             ));
  //           } else if (data['is_verified'] == true &&
  //               data['user_account_id'] != null) {
  //             timer.cancel();
  //             Navigator.pop(navigatorKey.currentState!.context);
  //           }
  //         }
  //       } else {
  //         Navigator.pop(navigatorKey.currentState!.context);
  //       }
  //     } catch (e) {
  //       print("Error sending email verification: $e");
  //       timer.cancel();
  //       Navigator.pop;
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_outlined,
                color: Color(0xff4A8AF0),
                size: 120,
              ),
              const SizedBox(height: 20),
              const Text(
                'Application under review',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              const Text(
                'Thank you for submitting your application. Your application is now being review. Our team will carefully review it and get back to you as soon as possible. Please check your email for further updates.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await Provider.of<ProfileProvider>(context, listen: false)
                      .initializeToken();
                  await Provider.of<FavoriteProvider>(context, listen: false)
                      .initializeFave();

                  await firebaseApi.requestNotificationPermission();

                  String? token = await FirebaseMessaging.instance.getToken();
                  if (token != null && token.isNotEmpty) {
                    await apiService.saveFcmToken(token);
                  } else {
                    print("Error: Failed to retrieve FCM token.");
                  }

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4A8AF0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue browsing',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 25,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
