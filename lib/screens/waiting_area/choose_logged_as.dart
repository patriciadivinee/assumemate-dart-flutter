import 'package:assumemate/provider/usertype_provider.dart';
import 'package:assumemate/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChooseLoggedAs extends StatelessWidget {
  const ChooseLoggedAs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Consumer<UserProvider>(builder: (context, userprovider, child) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Conitnue to logged in as',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: MediaQuery.of(context).size.width *
                        0.8, // 80% of the screen width
                    height: 50, // Fixed height
                    child: ElevatedButton(
                      onPressed: () async {
                        userprovider.setUserType('assumptor');
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4A8AF0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        "Assumptor",
                        style: TextStyle(
                          color: Color(0xffFFFEF7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width *
                        0.8, // 80% of the screen width
                    height: 50, // Fixed height
                    child: ElevatedButton(
                      onPressed: () async {
                        userprovider.setUserType('assumee');
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4A8AF0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        "Assumee",
                        style: TextStyle(
                          color: Color(0xffFFFEF7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ));
    }));
  }
}
