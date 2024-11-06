import 'package:assumemate/format.dart';
import 'package:flutter/material.dart';
// import 'package:assumemate/logo/check_splash.dart';
// import 'package:assumemate/screens/user_auth/create_profile_screen.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/screens/home_screen.dart';
import 'package:assumemate/screens/user_auth/forgot_password_screen.dart';
// import 'package:assumemate/screens/waiting_area/pending_application_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/screens/user_auth/signup_choice_screen.dart';
import 'package:provider/provider.dart';

import '../../provider/profile_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key to validate the form
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  final ApiService apiService = ApiService();
  late bool users;
  bool _isLoading = false;

  void clearControllers() {
    _emailController.clear();
    _passwordController.clear();
  }

  Future<void> _signInWithGoogle() async {
    final user = await GoogleSignInApi.login();
    if (user == null) {
      popUp(context, 'User cancelled');
      return;
    }

    final googleAuth = await user.authentication;

    // final String googleId = user.id;
    // final String email = user.email;

    print(googleAuth.idToken);
    final token = googleAuth.idToken;
    _loginUser(token, null, null);
  }

  void _loginWithPassword() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      _loginUser(null, email, password);
    } catch (e) {
      popUp(context, 'An error occured: $e');
    }
  }

  void _loginUser(String? token, String? email, String? password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.loginUser(token, email, password);

      if (response.containsKey('error')) {
        popUp(context, response['error']);
      } else {
        await Provider.of<ProfileProvider>(context, listen: false)
            .initializeToken();
        await Provider.of<FavoriteProvider>(context, listen: false)
            .initializeFave();
        // final status = response['is_approved'];
        // final token = response['access_token'];
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      popUp(context, 'Error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        text: "LOG IN TO",
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
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        onTapOutside: (event) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        style: const TextStyle(fontSize: 13),
                        cursorColor: const Color(0xff4A8AF0),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(12),
                          hintText: "EMAIL",
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xff4A8AF0),
                          ),
                          enabledBorder: borderStyle,
                          focusedBorder: borderStyle,
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
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16), // Spacing

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        onTapOutside: (event) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        style: const TextStyle(fontSize: 13),
                        cursorColor: const Color(0xff4A8AF0),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(12),
                          hintText: "PASSWORD",
                          floatingLabelStyle: const TextStyle(
                            color: Color(
                                0xff4A8AF0), // Set your desired color here
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: const BorderSide(
                                color: Colors.black,
                              )),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: const BorderSide(
                                color: Color(0xff4A8AF0),
                              )),
                          prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 10),
                              child: Icon(Icons.lock)),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 7),
                            child: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        obscureText: _obscureText,
                      ),

                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xff4A8AF0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24), // Spacing

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  print(_isLoading);
                                  _loginWithPassword();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF4A8AF0), // Custom button color
                          // padding: const EdgeInsets.all(20),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: (_isLoading)
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xffFFFCF1),
                                ),
                              )
                            : const Text(
                                "Log in",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 22),

                      Row(children: [
                        Expanded(
                          child: Container(
                              margin: const EdgeInsets.only(
                                  left: 10.0, right: 15.0),
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
                              margin: const EdgeInsets.only(
                                  left: 15.0, right: 10.0),
                              child: Divider(
                                color: Colors.grey.shade600,
                                height: 1,
                              )),
                        ),
                      ]),

                      const SizedBox(height: 22),

                      ElevatedButton.icon(
                          onPressed: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //       builder: (context) => const SignupScreen()),
                            // );
                            _signInWithGoogle();
                          },
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FaIcon(
                              FontAwesomeIcons.google,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffF04F4F),
                            // padding: const EdgeInsets.all(20),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          )),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account yet? ",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.black),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                ).then((value) {
                                  clearControllers();
                                });
                              },
                              child: const Text(
                                'Sign Up',
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
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // @override
  // void dispose() {
  //   _emailController.dispose();
  //   _passwordController.dispose();
  //   super.dispose();
  // }
}
