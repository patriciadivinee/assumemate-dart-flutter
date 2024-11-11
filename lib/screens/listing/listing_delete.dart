import 'package:flutter/material.dart';
import '../../service/service.dart'; // Adjusted import path for ApiService1
import '../../storage/secure_storage.dart'; // Adjusted import path for SecureStorage

class DeleteService {
  final ApiService apiService1 = ApiService();
  final SecureStorage secureStorage = SecureStorage();

  Future<void> deleteListing(BuildContext context, String listingId) async {
    final shouldDelete = await _showConfirmationDialog(context);
    final token = await secureStorage.getToken();

    if (shouldDelete) {
      try {
        // Call the delete method in the API service to handle deletion
        await apiService1.deleteListing(listingId, token!);

        _showMessage(context, 'Listing archived successfully!');
      } catch (e) {
        _showMessage(context, 'Error archiving listing. Please try again.');
      }
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Listing'),
          content: const Text('Are you sure you want to archive this listing?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
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
