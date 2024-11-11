import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:assumemate/storage/secure_storage.dart';

class FollowProvider with ChangeNotifier {
  List<Map<String, dynamic>> _followingIds = [];
  int _followingCount = 0;

  final SecureStorage secureStorage = SecureStorage();
  String _token = '';

  List<Map<String, dynamic>> get followingIds => _followingIds;
  int get followingCount => _followingCount;

  Future<void> initializeFollow() async {
    _token = await secureStorage.getToken() ?? '';
    if (_token.isNotEmpty) {
      await fetchFollowings(_token);
    }
    print(_followingIds);
  }

  Future<void> fetchFollowings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/follow/mark'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> followingData = json.decode(response.body);
        _followingIds =
            List<Map<String, dynamic>>.from(followingData['following']);
        _followingCount = _followingIds.length;
        notifyListeners();
      } else {
        throw Exception('Failed to load followings');
      }
    } catch (e) {
      print('Error fetching followings: $e');
    } finally {
      print(_followingIds);
    }
  }

  Future<String> toggleFollowing(String userId) async {
    if (isFollowing(userId)) {
      // Unfollow the user
      try {
        final response = await http.delete(
          Uri.parse('${dotenv.env['API_URL']}/user/unfollow/'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'user_id': userId}),
        );

        print('Unfollow response code: ${response.statusCode}');
        if (response.statusCode == 200) {
          _followingIds
              .removeWhere((item) => item['user_id'].toString() == userId);
          _followingCount = _followingIds.length;
          notifyListeners();
          return 'Removed from following';
        } else {
          return 'Failed to unfollow: ${response.body}'; // Detailed error message
        }
      } catch (e) {
        return 'Network error occurred while unfollowing: $e'; // More descriptive error
      }
    } else {
      // Follow the user
      try {
        final response = await http.post(
          Uri.parse('${dotenv.env['API_URL']}/user/follow/'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'user_id': userId}),
        );

        print('Follow response: ${response.body}'); // Debugging response
        if (response.statusCode == 200) {
          final newFollowing = jsonDecode(response.body);
          _followingIds.add(newFollowing);
          _followingCount = _followingIds.length;
          notifyListeners();
          return 'Added to following';
        } else {
          return 'Failed to follow: ${response.body}'; // Detailed error message
        }
      } catch (e) {
        return 'Network error occurred while following: $e'; // More descriptive error
      }
    }
  }

  bool isFollowing(String userId) {
    return _followingIds.any((item) => item['user_id'].toString() == userId);
  }
}
