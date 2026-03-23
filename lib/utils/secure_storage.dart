import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
    await _storage.write(key: 'biometricEnabled', value: 'true');
  }

  static Future<Map<String, String?>> getCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    final enabled = await _storage.read(key: 'biometricEnabled');
    return {
      'email': email,
      'password': password,
      'enabled': enabled,
    };
  }

  static Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}