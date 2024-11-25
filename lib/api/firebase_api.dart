import 'dart:convert';
import 'package:assumemate/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assumemate/storage/secure_storage.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SecureStorage secureStorage = SecureStorage();
  late final String baseURL;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FirebaseApi() {
    baseURL = dotenv.env['API_URL'] ?? '';
    _initializeLocalNotifications();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        if (notificationResponse.payload != null) {
          final data = json.decode(notificationResponse.payload!);
          _handleNotificationPayload(data); // Handle notification click
        }
      },
    );
  }

  // Initialize Firebase and notifications
  Future<void> initNotifications(GlobalKey<NavigatorState> navigatorKey) async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);

      // Immediately update application status without clicking the notification
      final data = message.data;
      if (data.containsKey('application_status')) {
        String status = data['application_status'];
        print("Received updated application status: $status");
        storeApplicationStatus(status);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRedirectData(message);
    });
  }

  // Request notification permission when button is clicked
  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // Save the permission status to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('permissionRequested', true); // Mark permission as granted
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User denied notification permission');
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  // Show notification in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',
      channelDescription: 'Your Channel Description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: json.encode({
        'route': message.data['route'] ?? '',
        'listingId': message.data['listingId'] ?? '',
        'userId': message.data['userId'] ?? '',
        'application_status': message.data['application_status'] ?? '',
      }),
    );
  }

  // Handle notification payload when tapped
  void _handleNotificationPayload(Map<String, dynamic> data) {
    print("Full notification payload data: $data");

    if (data['application_status'] != null &&
        data['application_status']!.isNotEmpty) {
      String status = data['application_status'];
      print("Received updated application status: $status");
      storeApplicationStatus(status);
    } else {
      print("No valid 'application_status' key found in notification payload.");
    }

    if (data.containsKey('route')) {
      String route = data['route'];
      print("Received route: $route");
      route = route.replaceAll(RegExp(r'//+'), '/');
      print("Normalized route: $route");

      List<String> routeParts = route.split('/');
      print("Splitted route parts: $routeParts");

      // Check for profile route
      if (route.startsWith('view/') && route.endsWith('/profile')) {
        String userId = routeParts.length > 2 ? routeParts[1] : '';
        print("Extracted userId: $userId");
        navigatorKey.currentState?.pushNamed(
          'view/$userId/profile',
          arguments: {'userId': userId},
        );
      } else if (route.startsWith('/listings/details/') &&
          data.containsKey('listingId')) {
        // Handle listing route
        String listingId = data['listingId'] ?? '';
        String userId = data['userId'] ?? '';
        print(
            "Navigating to listing details route: $route with listingId: $listingId and userId: $userId");
        navigatorKey.currentState?.pushNamed(
          '/listings/details/',
          arguments: {'listingId': listingId, 'userId': userId},
        );
      } else if (route.startsWith('ws/chat/') &&
          data.containsKey('listingId')) {
        print("Navigating to chat route: $route");
        String userId = data['userId'] ?? '';
        navigatorKey.currentState?.pushNamed(
          'ws/chat/',
          arguments: {'userId': userId},
        );
      } else {
        // Unexpected route or unsupported payload
        print("Unexpected route or payload: $data");
      }
    } else {
      print("No 'route' key found in notification payload.");
    }
  }

  // Handle redirect data from notification taps
  void _handleRedirectData(RemoteMessage message) {
    final data = message.data;
    _handleNotificationPayload(data); // Centralize handling
  }

  Future<void> storeApplicationStatus(String applicationStatus) async {
    String? currentStatus = await secureStorage.read(key: 'app_status');

    print(
        'Current application status in SecureStorage: ${currentStatus ?? "Not Set"}');

    // Save the new application status to SecureStorage
    await secureStorage.write(key: 'app_status', value: applicationStatus);

    print('Updated application status in SecureStorage: $applicationStatus');
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print("Subscribed to topic: $topic");
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print("Unsubscribed from topic: $topic");
  }
}
