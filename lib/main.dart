import 'package:assumemate/provider/follow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assumemate/logo/loading_animation.dart';
// import 'package:assumemate/screens/home_screen.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/provider/profile_provider.dart';
import 'package:assumemate/provider/photos_permission.dart';
import 'package:assumemate/provider/storage_permission.dart';
import 'package:assumemate/screens/home_screen.dart';
// import 'package:assumemate/screens/waiting_area/pending_application_screen.dart';
// import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:assumemate/logo/welcome.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final profileProvider = ProfileProvider();
  final faveProvider = FavoriteProvider();
  final followProvider = FollowProvider();

  final token = await profileProvider.secureStorage.getToken();

  if (token != null && token.isNotEmpty) {
    await profileProvider.initializeToken();
    await faveProvider.initializeFave();
    await followProvider.initializeFollow();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    GoogleFonts.config.allowRuntimeFetching = false;
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => profileProvider),
          ChangeNotifierProvider(create: (_) => faveProvider),
          ChangeNotifierProvider(create: (_) => followProvider),
          ChangeNotifierProvider(create: (_) => PhotosPermission()),
          ChangeNotifierProvider(create: (_) => StoragePermission()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  final SecureStorage secureStorage = SecureStorage();

  MyApp({super.key});

  Future<Map<String, String?>> _loadUserData() async {
    final token = await secureStorage.getToken();
    final applicationStatus = await secureStorage.getApplicationStatus();
    return {
      'token': token,
      'applicationStatus': applicationStatus,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Assumemate',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: const Color(0xff4A8AF0),
            selectionColor: const Color(0xff4A8AF0).withOpacity(.4),
            selectionHandleColor: const Color(0xff4A8AF0)),
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: const Color(0xffFFFCF1),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xffFFFCF1)),
        primaryColor: const Color(0xff4A8AF0),
        brightness: Brightness.light,
      ),
      home: FutureBuilder<Map<String, String?>>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingAnimation();
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final token = data['token'];
            // final applicationStatus = data['applicationStatus'];
            if (token != null) {
              return const HomeScreen();
            } else {
              return const WelcomeScreen();
            }
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
