import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final String? baseURL = dotenv.env['API_URL'];

  Future<void> addCarListing(
      String token, Map<String, dynamic> listingContent) async {
    final response = await http.post(
      Uri.parse('$baseURL/add/listings/'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        'list_content': listingContent,
        'list_status': 'active',
        'list_duration': DateTime.now().toIso8601String(),
      }),
    );

    // Check for errors in the response
    if (response.statusCode == 400) {
      final errorResponse = json.decode(response.body);
      // Access the 'detail' key from the error response
      throw Exception(errorResponse['detail']); // Use the key 'detail'
    } else if (response.statusCode != 201) {
      throw Exception('Failed to create listing: ${response.body}');
    }
  }
}
