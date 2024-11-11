import 'dart:convert';

import 'package:flutter/material.dart';
import '../../service/service.dart'; // Adjusted import for ApiService1
import '../../storage/secure_storage.dart'; // Adjusted import for SecureStorage

class PromotionService {
  final ApiService apiService1 = ApiService();
  final SecureStorage secureStorage = SecureStorage();
  double amount = 20;

  Future<void> promoteListing(BuildContext context, String listingId) async {
    final shouldPromote = await _showConfirmationDialog(context);
    final token = await secureStorage.getToken();
    if (shouldPromote) {
      final wallId = await secureStorage.getUserId();
      if (wallId == null) {
        // Handle case where user ID is not found
        return;
      }

      try {
        // Deduct 20 coins
        await apiService1.deductCoins(
            listingId, int.parse(wallId), amount, token!);

        // Add to promote_listing table
        await apiService1.promoteListing(listingId, token, amount);

        _showMessage(context, 'Listing promoted successfully!');
      } catch (e) {
        print('Error during promotion: $e');

        // Default error message
        String errorMessage = 'Error promoting listing. Please try again.';
        // Extracting the specific error message from the exception
        if (e.toString().contains('Failed to deduct coins:')) {
          // Attempt to parse the response body
          var parts = e.toString().split(' - ');

          if (parts.length > 1) {
            // Assuming the error message is in JSON format
            final errorResponse =
                json.decode(parts[1]); // Decode the JSON string
            if (errorResponse is List && errorResponse.isNotEmpty) {
              errorMessage =
                  errorResponse[0]; // Get the first message in the array
            }
          }
        }
        _showMessage(context, errorMessage); // Show the specific error message
      }
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Promote Listing'),
          content: const Text('Pay 20 coins to promote listing?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
