import 'package:assumemate/screens/user_auth/google_create_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/screens/user_auth/create_profile_screen.dart';
import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:assumemate/screens/user_auth/signup_choice_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(children: [
              Container(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                  ),
                  child: ClipRRect(
                    child: Image.asset(
                      'assets/images/15-removebg-preview.png',
                      width: MediaQuery.of(context).size.width * .45,
                      fit: BoxFit.cover,
                    ),
                  )),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                textScaler: const TextScaler.linear(1.5),
                text: const TextSpan(
                    text: "WELCOME TO",
                    style: TextStyle(
                        fontSize: 30,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: " ASSUMEMATE",
                        style: TextStyle(
                            fontSize: 30,
                            color: Color(0xff4A8AF0),
                            fontWeight: FontWeight.bold),
                      ),
                    ]),
              ),
            ]),
            const SizedBox(height: 70),
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
                padding: const EdgeInsets.all(15),
                minimumSize: const Size(double.infinity, 50),
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
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateProfileScreen(
                            email: 'example@gmail.com',
                          )
                      // const SignupScreen(),
                      ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                minimumSize: const Size(double.infinity, 50),
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
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
