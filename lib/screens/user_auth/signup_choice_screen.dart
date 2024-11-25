// ignore_for_file: unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/logo/welcome.dart';
import 'package:assumemate/screens/user_auth/google_create_profile_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/main.dart';
import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:assumemate/screens/waiting_area/waiting_email_verification.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:assumemate/format.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final ApiService apiService = ApiService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> signUpWithGoogle() async {
    final user = await GoogleSignInApi.login();
    if (user == null) {
      return;
    }

    final googleAuth = await user.authentication;

    _checkEmail(googleAuth.idToken!);
  }

  void _checkEmail(String token) async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final response = await apiService.checkUserEmail(token);

      print(response);

      if (response.containsKey('google_id')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => GoogleCreateProfileScreen(
                  email: response['email'], googleId: response['google_id'])),
        );
      } else {
        await GoogleSignInApi.logout();
        popUp(context, response['error']);
      }
    } catch (e) {
      await GoogleSignInApi.logout();
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  void _emailVerify() async {
    setState(() {
      _isLoading = true;
    });
    String email = _emailController.text.trim();

    try {
      final response = await apiService.emailVerification(email);

      if (response.containsKey('success')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => WaitingEmailVerification(email: email)),
        );
      } else {
        popUp(context, 'taena ${response['error']}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void clearControllers() {
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFFFCF1),
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
          onPressed: () {
            Navigator.of(context).pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(children: [
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
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(
                            text: " ASSUMEMATE",
                            style: TextStyle(
                                fontSize: 20,
                                color: Color(0xff4A8AF0),
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                  ),
                ]),
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(12),
                          hintText: 'Email Address',
                          focusedBorder: borderStyle,
                          enabledBorder: borderStyle,
                          border: borderStyle,
                          prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 10),
                              child: Icon(Icons.email)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading || _isGoogleLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _emailVerify();
                              }
                            },
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(const Color(0xff4A8AF0)),
                        minimumSize: WidgetStateProperty.all(
                            const Size(double.infinity, 50)),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      child: (_isLoading)
                          ? const SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: Color(0xffFFFCF1),
                              ),
                            )
                          : const Text(
                              "Sign up",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                    const SizedBox(height: 22),
                    Row(children: [
                      Expanded(
                        child: Container(
                            margin:
                                const EdgeInsets.only(left: 10.0, right: 15.0),
                            child: Divider(
                              color: Colors.grey.shade600,
                              height: 1,
                            )),
                      ),
                      Text(
                        'or',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Expanded(
                        child: Container(
                            margin:
                                const EdgeInsets.only(left: 15.0, right: 10.0),
                            child: Divider(
                              color: Colors.grey.shade600,
                              height: 1,
                            )),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                        onPressed: _isGoogleLoading || _isLoading
                            ? null
                            : () {
                                signUpWithGoogle();
                              },
                        icon: _isGoogleLoading
                            ? null
                            : const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: FaIcon(
                                  FontAwesomeIcons.google,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(const Color(0xffF04F4F)),
                          minimumSize: WidgetStateProperty.all(
                              const Size(double.infinity, 50)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                        label: _isGoogleLoading
                            ? const SizedBox(
                                height: 30,
                                width: 30,
                                child: CircularProgressIndicator(
                                  color: Color(0xffFFFCF1),
                                ),
                              )
                            : const Text(
                                'Sign up with Google',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                              )),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              ).then((value) {
                                clearControllers();
                              });
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff4A8AF0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
