import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/main.dart';
import 'package:assumemate/screens/user_auth/create_profile_screen.dart';
// import 'package:assumemate/screens/home_screen.dart';
import 'dart:convert';

import 'package:assumemate/service/service.dart';
// import 'package:assumemate/screens/user_auth/waiting_email_verification.dart';

class WaitingEmailVerification extends StatefulWidget {
  const WaitingEmailVerification({super.key, required this.email});

  final String email;

  @override
  State<WaitingEmailVerification> createState() =>
      _WaitingEmailVerificationState();
}

class _WaitingEmailVerificationState extends State<WaitingEmailVerification> {
  final ApiService apiService = ApiService();
  Timer? _timer;
  int _countdown = 60;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        // Add any action after the countdown ends, if needed
      }
    });
  }

  void waitForVerification() {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      final String? baseURL = dotenv.env['API_URL'];
      final apiUrl = Uri.parse('$baseURL/check-user-verification/');
      final Map<String, dynamic> userEmail = {
        'user_verification_email': widget.email,
      };

      try {
        final response = await http.post(
          apiUrl,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(userEmail),
        );

        if (response.statusCode == 200) {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['is_verified'] == true &&
                data['user_account_id'] == null) {
              timer.cancel(); // Stop polling
              navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(
                    builder: (context) =>
                        CreateProfileScreen(email: widget.email)),
              );
            } else if (data['is_verified'] == true &&
                data['user_account_id'] != null) {
              timer.cancel();
              Navigator.pop(navigatorKey.currentState!.context);
            }
          }
        } else {
          timer.cancel();
          Navigator.pop(navigatorKey.currentState!.context);
        }
      } catch (e) {
        print("Error sending email verification: $e");
        timer.cancel();
        Navigator.pop;
      }
    });
  }

  void _emailVerify() async {
    String email = widget.email;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.emailVerification(email);
      if (response.containsKey('success')) {
        popUp(context, 'Verification link has been sent!',
            align: TextAlign.center);
        setState(() {
          _countdown = 60;
          _startCountdown();
        });
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    waitForVerification();
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        _timer?.cancel();
      },
      child: Scaffold(
        body: Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: const Color(0xff4A8AF0)),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 60,
                    color: Color(0xffFFFEF7),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Verify your email address',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 17),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    'We\'ve sent an email to ${widget.email} to verify your email address and activate your account. The link in the email will expire in 24 hours.',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 17),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    'If you didn\'t recieved the email, please click the button below.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                    onPressed:
                        (_countdown == 0 && !_isLoading) ? _emailVerify : null,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(_countdown != 0
                          ? Colors.grey.shade400
                          : const Color(0xff4A8AF0)),
                      minimumSize: WidgetStateProperty.all(
                          const Size(double.infinity, 50)),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              color: Color(0xffFFFCF1),
                            ),
                          )
                        : Text(
                            (_countdown == 0)
                                ? 'Resend verification email'
                                : 'Resend in $_countdown seconds',
                            style: const TextStyle(
                                color: Color(0xffFFFEF7),
                                fontWeight: FontWeight.bold,
                                fontSize: 17),
                          )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
