import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/profile_provider.dart';
import 'package:assumemate/provider/usertype_provider.dart';
import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  final ApiService apiService = ApiService();

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

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final userType = Provider.of<UserProvider>(context).userType;

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
          "Account Information",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xffFFFEF7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Type',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(userType),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email Address',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(profileProvider.userProfile['email']),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone Number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(profileProvider.userProfile['user_prof_mobile']),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
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
                    "Deactivate Account",
                    style: TextStyle(
                      color: Color(0xffFFFEF7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
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
