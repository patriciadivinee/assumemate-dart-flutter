import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:assumemate/logo/welcome.dart';
import 'package:assumemate/screens/home_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:assumemate/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PendingApplicationScreen extends StatelessWidget {
  PendingApplicationScreen({super.key});

  final SecureStorage secureStorage = SecureStorage();

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
              ElevatedButton.icon(
                  onPressed: () async {
                    await secureStorage.clearTokens();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                    );
                  },
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffF04F4F),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  label: const Text(
                    'LOG OUT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
