// import 'package:flutter/material.dart';
// import 'package:messagetrial/service/service.dart';
// import 'package:messagetrial/storage/secure_storage.dart';

// class InboxProvider with ChangeNotifier {
//   final ApiService apiService = ApiService();
//   final SecureStorage secureStorage = SecureStorage();
//   String _token = '';
//   String _errorMessage = '';
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _inbox = [];

//   List<Map<String, dynamic>> get inbox => _inbox;
//   String get errorMessage => _errorMessage;
//   bool get isLoading => _isLoading;

//   Future<void> initializeToken() async {
//     _token = await secureStorage.getToken() ?? '';
//     if (_token.isNotEmpty) {
//       await getInbox();
//     }
//   }

//   void clearErrorMessage() {
//     _errorMessage = '';
//     notifyListeners();
//   }

//   Future<void> getInbox() async {
//     _isLoading = true; // Set loading to true
//     notifyListeners();

//     try {
//       final response = await apiService.viewInbox(_token);

//       if (response.containsKey('rooms')) {
//         _inbox = List<Map<String, dynamic>>.from(response['rooms']);
//       } else {
//         _errorMessage = response['error'] ?? "An unknown error occurred";
//       }
//     } catch (e) {
//       _errorMessage = 'Failed to load profile: $e';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateMessageIsRead(Map<String, dynamic> updatedData) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final response = await apiService.updateProfile(updatedData);
//       if (response.containsKey('user_profile')) {
//         _inbox = response['user_profile']; // Update local profile data
//         _errorMessage = '';
//       } else {
//         _errorMessage = response['error'] ?? "An unknown error occurred";
//       }
//     } catch (e) {
//       _errorMessage = 'Failed to update read property: $e';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
