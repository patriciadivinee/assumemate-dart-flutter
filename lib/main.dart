import 'package:assumemate/api/firebase_api.dart';
import 'package:assumemate/provider/follow_provider.dart';
import 'package:assumemate/provider/usertype_provider.dart';
import 'package:assumemate/screens/account_settings_screen.dart';
import 'package:assumemate/screens/assumptor_list_detail_screen.dart';
import 'package:assumemate/screens/chat_message_screen.dart';
import 'package:assumemate/screens/other_profile_screen.dart';
import 'package:assumemate/screens/report_list.dart';
import 'package:assumemate/service/service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final profileProvider = ProfileProvider();
  final faveProvider = FavoriteProvider();
  final followProvider = FollowProvider();
  final userProvider = UserProvider();
  final token = await profileProvider.secureStorage.getToken();

  // jericho
  await Firebase.initializeApp();
  FirebaseApi firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications(navigatorKey);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message received: ${message.notification?.title}");
  });
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  if (token != null && token.isNotEmpty) {
    await profileProvider.initializeToken();
    await faveProvider.initializeFave();
    await followProvider.initializeFollow();
    await checkNotificationPermission();
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
          ChangeNotifierProvider(create: (_) => userProvider),
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

Future<void> checkNotificationPermission() async {
  final prefs = await SharedPreferences.getInstance();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final ApiService apiService = ApiService();

  final notifStatus = await messaging.getNotificationSettings();

  final isGranted =
      notifStatus.authorizationStatus == AuthorizationStatus.authorized;

  prefs.setBool('push_notifications', isGranted);
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    if (!isGranted) {
      // If permission is denied or not determined, remove the FCM token.

      await apiService.removeFcmToken(fcmToken);
      await FirebaseMessaging.instance.deleteToken();
    } else {
      await apiService.saveFcmToken(fcmToken);
    }
  }
}

Future<void> backgroundHandler(RemoteMessage message) async {
  print("Background message: ${message.notification?.title}");
}

// Function to download image from a URL and save it locally
// Future<String?> downloadAndSaveImage(String url, String fileName) async {
//   try {
//     var http;
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final directory = await getTemporaryDirectory();
//       final imagePath = '${directory.path}/$fileName';
//       final file = File(imagePath);
//       await file.writeAsBytes(response.bodyBytes);
//       return imagePath;
//     }
//   } catch (e) {
//     print('Error downloading image: $e');
//   }
//   return null;
// }

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
      locale: Locale('en', 'PH'),
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
      initialRoute: '/', // Set initial route to check for user status
      routes: {
        '/': (context) => FutureBuilder<Map<String, String?>>(
              future: _loadUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingAnimation();
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;
                  final token = data['token'];
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
        '/settings': (context) => AccountSettingsScreen(),
      },
      onGenerateRoute: (settings) {
        print('Route name: ${settings.name}');
        print('Arguments: ${settings.arguments}');
        // Check for the '/item-details' route with arguments
        if (settings.name == '/item-details') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            final listingId = args['listingId'];
            final userId = args['user_id'];

            print("Listing ID: $listingId, User ID: $userId");

            return MaterialPageRoute(
              builder: (context) =>
                  AssumptorListDetailScreen(listingId: listingId),
            );
          }
        } // Check for the '/listings/details/' route with arguments
        else if (settings.name == '/listings/details/') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args != null) {
            final listingId = args['listingId'];
            final userId = args['userId'];

            print("Listing ID: $listingId, User ID: $userId");

            return MaterialPageRoute(
              builder: (context) =>
                  AssumptorListDetailScreen(listingId: listingId),
            );
          }
        } else if (settings.name?.startsWith('view/') == true) {
          print("Received route: ${settings.name}");
          final parts = settings.name?.split('/');
          print("Splitted route parts: $parts");

          if (parts != null && parts.length >= 2) {
            final userId = parts[1];
            print(userId);
            if (settings.name?.endsWith('/profile') == true) {
              if (userId.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (context) => OtherProfileScreen(userId: userId),
                );
              } else {
                print('Invalid userId in the URL');
              }
            } else {
              print('Route does not end with /profile: ${settings.name}');
            }
          } else {
            print('Invalid URL format: ${settings.name}');
          }
        } else if (settings.name?.startsWith('ws/chat/') ?? false) {
          print('Matched ws/chat/ route. Full route: ${settings.name}');

          final userId = settings.arguments != null
              ? (settings.arguments as Map<String, dynamic>)['userId']
                  .toString()
              : null;

          print('Extracted userId: $userId');

          if (userId != null) {
            print('Navigating to ChatMessageScreen for userId: $userId');
            return MaterialPageRoute(
              builder: (context) => ChatMessageScreen(receiverId: userId),
            );
          } else {
            print('Failed');
          }
        } else if (settings.name == 'reports/received/') {
          return MaterialPageRoute(
            builder: (context) => ReportListScreen(),
          );
        } else if (settings.name == 'reports/sent/') {
          return MaterialPageRoute(
            builder: (context) => ReportListScreen(),
          );
        }

        return MaterialPageRoute(builder: (context) => const Scaffold());
      },
    );
  }
}
