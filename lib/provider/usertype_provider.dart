import 'package:flutter/foundation.dart';
import 'package:assumemate/storage/secure_storage.dart';

class UserProvider with ChangeNotifier {
  String _userType = 'guest';
  bool _isAssumptor = false;
  bool _isAssumee = false;
  final SecureStorage secureStorage = SecureStorage();

  String get userType => _userType;
  bool get isAssumptor => _isAssumptor;
  bool get isAssumee => _isAssumee;

  UserProvider() {
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    _userType = await secureStorage.getUserType() ?? 'guest';
    _isAssumptor = await secureStorage.getIsAssumptor();
    _isAssumee = await secureStorage.getIsAssumee();
    notifyListeners();
  }

  Future<void> setRoles(
      {required bool isAssumptor, required bool isAssumee}) async {
    _isAssumptor = isAssumptor;
    _isAssumee = isAssumee;

    await secureStorage.storeIsAssumptor(isAssumptor);
    await secureStorage.storeIsAssumee(isAssumee);
    notifyListeners();
  }

  Future<void> setUserType(String type) async {
    _userType = type;
    await secureStorage.storeUserType(type);
    notifyListeners();
  }
}
