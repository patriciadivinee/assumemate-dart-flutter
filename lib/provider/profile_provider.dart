import 'dart:io';

import 'package:flutter/material.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  final SecureStorage secureStorage = SecureStorage();
  String _token = '';
  String _errorMessage = '';
  bool _isLoading = false;
  Map<String, dynamic> _userProfile = {};

  // String _fname = '';
  // String _lname = '';
  // String _gender = '';
  // String _dob = '';
  // String _address = '';
  // String _mobile = '';

  // String get fname => _fname;
  // String get lname => _lname;
  // String get gender => _gender;
  // String get dob => _dob;
  // String get address => _address;
  // String get mobile => _mobile;
  Map<String, dynamic> get userProfile => _userProfile;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> initializeToken() async {
    _token = await secureStorage.getToken() ?? '';
    if (_token.isNotEmpty) {
      await fetchUserProfile();
    }
  }

  void clearErrorMessage() {
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true; // Set loading to true
    notifyListeners();

    try {
      final response = await apiService.viewProfile(_token);
      if (response.containsKey('user_profile')) {
        _userProfile = response['user_profile'];
        _errorMessage = '';
      } else {
        _errorMessage = response['error'] ?? "An unknown error occurred";
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updatedData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.updateProfile(updatedData);
      if (response.containsKey('user_profile')) {
        _userProfile = response['user_profile']; // Update local profile data
        _errorMessage = '';
      } else {
        _errorMessage = response['error'] ?? "An unknown error occurred";
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfilePicture(File picture) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.updateProfilePicture(picture);
      if (response.containsKey('message')) {
        _userProfile['user_prof_pic'] = response['url'];
        _errorMessage = '';
      } else {
        _errorMessage = response['error'] ?? "An unknown error occurred";
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
