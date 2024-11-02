import 'package:flutter/material.dart';
// import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
// import 'package:messagetrial/screens/waiting_area/pending_application_screen.dart';
// import 'package:page_transition/page_transition.dart';

class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffFFFCF1),
      child: Center(
        child: LottieBuilder.asset(
          'assets/animation/Animation - 1728615953315.json',
          repeat: true,
        ),
      ),
    );
    // body: AnimatedSplashScreen(
    //   splash: Center(
    //     child: LottieBuilder.asset(
    //       "assets/animation/Animation - 1726424646069.json",
    //       repeat: true,
    //     ),
    //   ),
    //   splashIconSize: 200,
    //   duration: 5000,
    //   nextScreen: const PendingApplicationScreen(),
    //   backgroundColor: const Color(0xffFFFEF7),
    //   pageTransitionType: PageTransitionType.fade,
    // ),
  }
}
