import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:assumemate/storage/secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this package

class NotificationModel {
  final int id;
  final int recipientId;
  final int? triggeredById;
  final String message;
  final bool isRead;
  final String createdAt;
  final String notificationType;
  final String? listId;
  final String? triggeredByProfilePic; // Add this field

  NotificationModel({
    required this.id,
    required this.recipientId,
    this.triggeredById,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.notificationType,
    this.listId,
    this.triggeredByProfilePic, // Add this to constructor
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notif_id'] ?? 0,
      recipientId: json['recipient_id'] ?? 0,
      triggeredById: json['triggered_by'],
      message: json['notif_message'] ?? 'No message provided',
      isRead: json['notif_is_read'] ?? false,
      createdAt: json['notif_created_at'] ?? 'Unknown date',
      notificationType: json['notification_type'] ?? 'general',
      listId: json['list_id'],
      triggeredByProfilePic: json['triggered_by_profile_pic'], // Add this field
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationModel>> notifications;
  final SecureStorage secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    notifications = fetchNotifications();
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    // If there's a profile picture and triggered by ID, show the profile picture
    if (notification.triggeredByProfilePic != null &&
        notification.triggeredById != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CachedNetworkImage(
            imageUrl: notification.triggeredByProfilePic!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 24,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.error,
                color: Colors.grey,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    // If no profile picture, show the default icon based on notification type
    IconData iconData;
    Color iconColor;

    switch (notification.notificationType.toLowerCase()) {
      case 'follow':
        iconData = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case 'like':
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'listing':
        iconData = Icons.list_alt;
        iconColor = Colors.green;
        break;
      case 'offer':
        iconData = Icons.local_offer;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  // Rest of the code remains the same until the notification item builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: const Color(0xff4A8AF0),
        child: FutureBuilder<List<NotificationModel>>(
          future: notifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No notifications available'));
            }

            var notificationList = snapshot.data!;

            return ListView.separated(
              itemCount: notificationList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                var notification = notificationList[index];

                return Material(
                  color: notification.isRead
                      ? Colors.white
                      : Colors.blue.withOpacity(0.05),
                  child: InkWell(
                    onTap: () {
                      // Handle listing notifications
                      if ((notification.notificationType == 'Listing' ||
                              notification.notificationType == 'like') &&
                          notification.listId != null) {
                        Navigator.pushNamed(
                          context,
                          '/item-details',
                          arguments: {
                            'listingId': notification.listId,
                            'user_id': notification.recipientId.toString(),
                          },
                        );
                      }
                      // Handle follow notifications
                      else if (notification.notificationType == 'follow' &&
                          notification.triggeredById != null) {
                        Navigator.pushNamed(
                          context,
                          'view/${notification.triggeredById}/profile',
                        );
                      }
                      // Handle offer notifications
                      else if (notification.notificationType == 'offer' &&
                          notification.triggeredById != null) {
                        Navigator.pushNamed(
                          context,
                          'ws/chat/${notification.triggeredById}/',
                          arguments: {'userId': notification.triggeredById},
                        );
                      } else if (notification.notificationType ==
                              'offer_status' &&
                          notification.triggeredById != null) {
                        Navigator.pushNamed(
                          context,
                          'ws/chat/${notification.triggeredById}/',
                          arguments: {'userId': notification.triggeredById},
                        );
                      } else if (notification.notificationType == 'Report' &&
                          notification.triggeredById != null) {
                        Navigator.pushNamed(
                          context,
                          'reports/received/',
                        );
                      } else if (notification.notificationType == 'Report' &&
                          notification.triggeredById != null) {
                        Navigator.pushNamed(
                          context,
                          'reports/sent/',
                        );
                      }

                      // Mark notification as read
                      markNotificationAsRead(notification.id);
                    },
                    child: Container(
                      // height: 96,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotificationIcon(
                              notification), // Updated to pass the whole notification
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: notification.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.createdAt,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final token = await secureStorage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('No token found');
    }

    final String? baseURL = dotenv.env['API_URL'];
    if (baseURL == null) {
      throw Exception('API URL is not defined in .env file');
    }

    try {
      final apiUrl = Uri.parse('$baseURL/notifications/');
      final response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      notifications = fetchNotifications();
    });
  }

  Future<void> markNotificationAsRead(int notifId) async {
    final token = await secureStorage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('No token found');
    }

    final String? baseURL = dotenv.env['API_URL'];
    if (baseURL == null) {
      throw Exception('API URL is not defined in .env file');
    }

    try {
      final apiUrl = Uri.parse('$baseURL/notifications/$notifId/read/');
      final response = await http.patch(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications = fetchNotifications();
        });
      } else {
        throw Exception(
            'Failed to mark notification as read: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }
}
