import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:assumemate/screens/home_screen.dart';
import 'package:assumemate/screens/waiting_area/pending_application_screen.dart';
import 'package:page_transition/page_transition.dart';

class CheckSplash extends StatelessWidget {
  const CheckSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: AnimatedSplashScreen(
      splash: Center(
        child: LottieBuilder.asset(
          "assets/animation/Animation - 1726421760413.json",
          repeat: true,
        ),
      ),
      splashIconSize: 200,
      duration: 700,
      nextScreen: PendingApplicationScreen(),
      backgroundColor: const Color(0xffFFFEF7),
      pageTransitionType: PageTransitionType.fade,
    ));
  }
}
