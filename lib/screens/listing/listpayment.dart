import 'dart:convert';
import 'package:flutter/material.dart';
import '../../service/service.dart'; // ApiService1
import '../../storage/secure_storage.dart'; // SecureStorage

class PaymentService {
  final ApiService apiService1 = ApiService();
  final SecureStorage secureStorage = SecureStorage();

  // Show confirmation dialog and process payment
  Future<void> processPayment(
      BuildContext context, String listingId, double amountToPay) async {
    final shouldPay = await _showConfirmationDialog(context, amountToPay);

    if (shouldPay) {
      final token = await secureStorage.getToken();
      final userIdString = await secureStorage.getUserId();

      if (userIdString == null || token == null) {
        _showMessage(context, 'Error: User not authenticated.');
        return;
      }

      try {
        final userId = int.parse(userIdString); // Convert to int

        // Check the current status of the listing
        final listingStatus =
            await apiService1.fetchListingStatus(listingId, token);

        if (listingStatus == 'ACTIVE') {
          _showMessage(context, 'Listing is already active.');
          return;
        }

        // Deduct the specified amount from the user's wallet
        await apiService1.deductCoins(listingId, userId, amountToPay, token);

        // Update the listing status to 'active' after successful payment
        await apiService1.updateListingStatus(listingId, token, amountToPay);

        // Handle the action after successful deduction (e.g., promote listing, etc.)
        _showMessage(context, 'Payment successful! Coins deducted.');
      } catch (e) {
        print('Error during payment: $e');

        // Default error message
        String errorMessage = 'Error during payment. Please try again.';

        // Check for insufficient coins error from backend
        if (e.toString().contains('Insufficient coins')) {
          errorMessage = 'Insufficient coins, please top up';
        }

        _showMessage(context, errorMessage); // Show the error message
      }
    }
  }

  // Show the confirmation dialog
  Future<bool> _showConfirmationDialog(
      BuildContext context, double amount) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Payment Confirmation'),
          content: Text('Pay $amount coins to proceed?'),
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

  // Show a message (success or error)
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
