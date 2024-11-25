import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> storeToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> storeUserType(String userType) async {
    await _storage.write(key: 'user_type', value: userType);
  }

  Future<String?> getUserType() async {
    return await _storage.read(key: 'user_type');
  }

  Future<void> storeApplicationStatus(String applicationStatus) async {
    await _storage.write(key: 'app_status', value: applicationStatus);
  }

  Future<String?> getApplicationStatus() async {
    return await _storage.read(key: 'app_status');
  }

  Future<void> storeUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_type');
    await _storage.delete(key: 'app_status');
    await _storage.delete(key: 'user_id');
  }

// jericho
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
}
