import 'dart:convert';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final String? baseURL = dotenv.env['API_URL'];
  final SecureStorage secureStorage = SecureStorage();

  Future<void> addCarListing(
      String token, Map<String, dynamic> listingContent) async {
    try {
      // Retrieve user_id from secure storage
      String? userId = await secureStorage.getUserId();
      if (userId == null) {
        throw Exception('User ID is not available');
      }

      // Include user_id in the request body
      final response = await http.post(
        Uri.parse('$baseURL/add/listings/'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          'list_content': listingContent,
          'list_status': 'PENDING',
          'list_duration':
              DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'user_id': userId, // Adding user_id to the request body
        }),
      );

      // Print response details for debugging
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check for errors in the response
      if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['detail']);
      } else if (response.statusCode != 201) {
        throw Exception('Failed to create listing: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow;
    }
  }
}
