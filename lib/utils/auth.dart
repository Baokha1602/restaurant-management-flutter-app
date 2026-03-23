import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/config_url.dart';
import '../services/auth_service.dart';

class Auth {
  static final AuthService _authService = AuthService();
  static final String baseUrl = "${Config_URL.baseApiUrl}/AccountApi";

  // ---------------- LOGIN ----------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    var result = await _authService.login(email, password);
    return result;
  }

  // ---------------- REGISTER ----------------
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNumber,
    required String dateOfBirth,
    required int gender,
    required int rankId,
    required String email,
    required String normalizedEmail,
    required String normalizedUserName,
    required String userName,
    required String password,
    required String confirmPassword,
    File? imageFile,
  }) async {
    // Gọi sang AuthService để xử lý API
    var result = await _authService.register(
      name: name,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      rankId: rankId,
      email: email,
      normalizedEmail: normalizedEmail,
      normalizedUserName: normalizedUserName,
      userName: userName,
      password: password,
      confirmPassword: confirmPassword,
      imageFile: imageFile,
    );

    // Trả kết quả về cho UI
    return result;
  }
}
