import 'package:flutter/material.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/screens/user_auth/change_password_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AccontSettingsScreen extends StatelessWidget {
  const AccontSettingsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();
    final subtitleStyle = GoogleFonts.poppins();
    // final favoriteProvider = Provider.of<FavoriteProvider>(context);

    return Scaffold(
        appBar: AppBar(
            backgroundColor: const Color(0xff4A8AF0),
            leading: IconButton(
              splashColor: Colors.transparent,
              icon: const Icon(
                Icons.arrow_back_ios,
              ),
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
            )),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                                          color: Colors.black),
                                    ),
                                    TextSpan(
                                      text:
                                          'See your account information like your email address, user type, and phone number', // Detail
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        ],
                      )),
                ),
                InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Padding(
                              padding: EdgeInsets.only(left: 3),
                              child: Icon(
                                Icons.lock_outlined,
                                color: Color.fromRGBO(74, 138, 240, 1),
                                size: 36,
                              )),
                          const SizedBox(width: 15),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                  style: subtitleStyle,
                                  children: const <TextSpan>[
                                    TextSpan(
                                      text:
                                          'Change your password\n', // Bold title
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors
                                              .black // Optional: make the title a bit larger
                                          ),
                                    ),
                                    TextSpan(
                                      text:
                                          'Change your password at anytime', // Detail
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () async {
                      await apiService.sessionExpired();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF4A8AF0), // Custom button color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 8),
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
                    )),
              ],
            ),
          ),
        ));
  }
}
