import 'package:flutter/foundation.dart';
import 'package:assumemate/storage/secure_storage.dart'; // Assuming you use secure storage

class UserProvider with ChangeNotifier {
  String _userType = 'guest'; // Default to guest or undefined
  final SecureStorage secureStorage = SecureStorage();

  String get userType => _userType;

  Future<void> setUserType(String type) async {
    _userType = type;
    notifyListeners();
    await secureStorage.storeUserType(type); // Save user type persistently
  }

  Future<void> logout() async {
    _userType = 'guest';
    notifyListeners();
    await secureStorage.clearTokens(); // Clear stored tokens and user type
  }
}
