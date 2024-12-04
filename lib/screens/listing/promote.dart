import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../service/service.dart'; // Adjusted import for ApiService1
import '../../storage/secure_storage.dart'; // Adjusted import for SecureStorage

class PromotionService {
  final ApiService apiService1 = ApiService();
  final SecureStorage secureStorage = SecureStorage();

  // Show the promotion options and process the selected one
  Future<void> showPromotionOptions(
      BuildContext context, String listingId) async {
    final selectedOption = await showPromotionDialog(context);

    if (selectedOption != null) {
      final token = await secureStorage.getToken();
      final wallId = await secureStorage.getUserId();

      if (wallId == null || token == null) {
        _showMessage(context, 'Error: User not authenticated.');
        return;
      }

      // Show a confirmation dialog before proceeding with payment
      final confirmed =
          await showPaymentConfirmationDialog(context, selectedOption);

      if (confirmed) {
        try {
          // Deduct coins based on the selected option
          await apiService1.deductCoins(
              listingId, int.parse(wallId), selectedOption['amount'], token!);

          // Add to promote_listing table
          await apiService1.promoteListing(listingId, token,
              selectedOption['amount'], selectedOption['duration']);

          _showMessage(context,
              '${selectedOption['duration']} days promotion applied successfully!');
        } catch (e) {
          print('Error during promotion: $e');

          // Default error message
          String errorMessage = 'Error promoting listing. Please try again.';

          // Check for error details
          if (e.toString().contains('Insufficient coins')) {
            errorMessage = 'Insufficient coins, please top up';
          } else if (e.toString().contains('list_id is required')) {
            errorMessage = 'Listing ID is required';
          } else if (e.toString().contains('Listing is already promoted')) {
            errorMessage = 'This listing is already promoted';
          }

          _showMessage(context, errorMessage); // Show the error message
        }
      }
    }
  }

  Future<Map<String, dynamic>?> showPromotionDialog(
      BuildContext context) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: AlertDialog(
            title: Text(
              'Choose Promotion Duration',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Select the promotion duration and cost:',
              style: TextStyle(color: Colors.black),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: <Widget>[
              _buildPromotionButton(
                context,
                text: '3 Days - 30',
                onPressed: () =>
                    Navigator.of(context).pop({'duration': 3, 'amount': 30.0}),
              ),
              _buildPromotionButton(
                context,
                text: '7 Days - 50',
                onPressed: () =>
                    Navigator.of(context).pop({'duration': 7, 'amount': 50.0}),
              ),
              _buildPromotionButton(
                context,
                text: '30 Days - 109',
                onPressed: () => Navigator.of(context)
                    .pop({'duration': 30, 'amount': 109.0}),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    ).then((value) => value);
  }

  // Show confirmation dialog for payment
  Future<bool> showPaymentConfirmationDialog(
      BuildContext context, Map<String, dynamic> selectedOption) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: AlertDialog(
            title: Text(
              'Payment Confirmation',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Pay ${selectedOption['amount']} coins to promote for ${selectedOption['duration']} days?',
              style: TextStyle(color: Colors.black),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  // Helper method to create consistent promotion buttons
  Widget _buildPromotionButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text + ' Coins '),
            const Icon(
              FontAwesomeIcons.coins,
              color: Color(0xffF2D120),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  // Show a message (success or error)
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
