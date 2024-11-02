import 'package:flutter/material.dart';
import 'package:assumemate/screens/user_auth/create_profile_screen.dart';
import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:assumemate/screens/user_auth/signup_choice_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonWidth = screenWidth * 0.8; // 80% of the screen width
    double buttonHeight = 60;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "WELCOME TO",
              style: TextStyle(
                fontSize: 45,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "ASSUMEMATE",
              style: TextStyle(
                fontSize: 45,
                color: const Color(0xFF4A8AF0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 100),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: const Color(0xFF4A8AF0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text(
                'LOG IN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CreateProfileScreen(email: 'example@gmail.com')
                      // const SignupScreen(),
                      ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                minimumSize: const Size(double.infinity, 40),
                side: const BorderSide(color: Color(0xff4A8AF0), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text(
                'SIGN UP',
                style: TextStyle(
                  color: Color(0xff4A8AF0),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
