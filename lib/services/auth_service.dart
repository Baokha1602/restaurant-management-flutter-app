import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import 'dart:convert';

class AuthService {
  // URL gốc cho AccountApi
  String get apiUrl => "${Config_URL.baseApiUrl}/AccountApi";

  // ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final fullUrl = '$apiUrl/Login';
      print("🟧 [LOGIN] Bắt đầu đăng nhập...");
      print("🔗 API URL: $fullUrl");
      print("📤 Request body: ${jsonEncode({
        "Email": email,
        "Password": password,
      })}");

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Email": email,
          "Password": password,
        }),
      );

      print("✅ [LOGIN] STATUS CODE: ${response.statusCode}");
      print("💬 [LOGIN] RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isSuccess = data['isSuccess'] ?? false;

        if (!isSuccess) {
          print("⚠️ [LOGIN] Đăng nhập thất bại: ${data['message']}");
          return {"success": false, "message": data['message']};
        }

        // ✅ Nếu thành công, lấy token
        String token = data['token'];
        print("🔑 [LOGIN] Token nhận được: $token");

        // ✅ Giải mã token
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        print("📦 [LOGIN] Token giải mã: $decodedToken");

        // ✅ Đọc thông tin user từ token
        // ✅ Đọc đúng các key claim từ token do .NET phát hành
        final userId = decodedToken['userId'] ?? '';
        final role = decodedToken['role'] ?? '';
        final userName = decodedToken['userName'] ?? '';
        final email = decodedToken['email'] ?? '';

        print("👤 [LOGIN] userId=$userId | role=$role | userName=$userName | email=$email");

        // ✅ Lưu dữ liệu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_id', userId);
        await prefs.setString('role', role);
        await prefs.setString('user_name', userName);
        await prefs.setString('email', email);

        print("💾 [LOGIN] Lưu thông tin người dùng thành công vào SharedPreferences");

        return {
          "success": true,
          "token": token,
          "decodedToken": decodedToken,
          "userId": userId,
          "role": role,
          "userName": userName,
          "email": email,
        };
      } else {
        print("❌ [LOGIN] Lỗi HTTP ${response.statusCode}: ${response.reasonPhrase}");
        return {
          "success": false,
          "message": "Failed to login: ${response.statusCode}"
        };
      }
    } catch (e) {
      print("🚨 [LOGIN] Network/Decode error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ---------------- REGISTER ----------------
  Future<Map<String, dynamic>> register({
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
    final url = Uri.parse('$apiUrl/Register');
    print("🟩 [REGISTER] Gửi yêu cầu đăng ký tới: $url");

    try {
      var request = http.MultipartRequest('POST', url);

      request.fields['Name'] = name;
      request.fields['PhoneNumber'] = phoneNumber;
      request.fields['DateOfBirth'] = dateOfBirth;
      request.fields['Gender'] = gender.toString();
      request.fields['RankId'] = rankId.toString();
      request.fields['Email'] = email;
      request.fields['NormalizedEmail'] = normalizedEmail;
      request.fields['NormalizedUserName'] = normalizedUserName;
      request.fields['UserName'] = userName;
      request.fields['Password'] = password;
      request.fields['ConfirmPassword'] = confirmPassword;

      if (imageFile != null && await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('ImageFile', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("✅ [REGISTER] STATUS CODE: ${response.statusCode}");
      print("💬 [REGISTER] RESPONSE BODY: ${response.body}");

      dynamic parsedBody;
      try {
        parsedBody = jsonDecode(response.body);
      } catch (_) {
        parsedBody = {"message": response.body};
      }

      return {
        "statusCode": response.statusCode,
        "body": parsedBody,
        "success": response.statusCode == 200,
      };
    } catch (e) {
      print("🚨 [REGISTER] Lỗi mạng hoặc xử lý form: $e");
      return {
        "statusCode": 500,
        "success": false,
        "body": {"message": "${e.toString()}"},
      };
    }
  }

  // ---------------- SEND OTP ----------------
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final url = Uri.parse('$apiUrl/SendOTP');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(resp.body);
      return {
        "success": resp.statusCode == 200,
        "message": data['message'] ?? 'Không rõ phản hồi',
        "userId": data['userId'] ?? data['UserId']
      };
    } catch (e) {
      return {"success": false, "message": "Lỗi mạng: $e"};
    }
  }
  // ---------------- VERIFY OTP ----------------
  Future<Map<String, dynamic>> verifyOTP(String userId, String otp) async {
    try {
      final url = Uri.parse('$apiUrl/VerifyOTP');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'otpCodeInput': otp,
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(resp.body);
      } catch (_) {
        data = resp.body;
      }

      print("🔍 [VERIFY OTP] STATUS: ${resp.statusCode}");
      print("💬 [VERIFY OTP] BODY: $data");

      bool success = false;
      String message = "Không rõ phản hồi";

      if (data is Map<String, dynamic>) {
        success = (data['isSuccess'] ?? data['success'] ?? (resp.statusCode == 200));
        message = data['message'] ?? data['Message'] ?? message;
      } else if (data is bool) {
        success = data;
        message = data ? "Xác thực OTP thành công" : "Xác thực OTP thất bại";
      } else if (data is String) {
        success = resp.statusCode == 200;
        message = data;
      }

      return {"success": success, "message": message};
    } catch (e) {
      return {"success": false, "message": "Lỗi mạng: $e"};
    }
  }

  // ---------------- CHANGE PASSWORD ----------------
  Future<Map<String, dynamic>> changePassword(String userId, String newPassword, String confirmPassword) async {
    try {
      final url = Uri.parse('$apiUrl/ChangePassword');
      print("🔐 [CHANGE PASSWORD] URL: $url");
      print("📤 Body: ${jsonEncode({
        'UserId': userId,
        'NewPassword': newPassword,
        'ConfirmPassword': confirmPassword
      })}");

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'UserId': userId,
          'NewPassword': newPassword,
          'ConfirmNewPassword': confirmPassword,
        }),
      );

      print("📩 [CHANGE PASSWORD] STATUS: ${resp.statusCode}");
      print("💬 [CHANGE PASSWORD] BODY: ${resp.body}");

      final data = jsonDecode(resp.body);
      return {
        "success": resp.statusCode == 200,
        "message": data['message'] ?? 'Không rõ phản hồi'
      };
    } catch (e) {
      print("🚨 [CHANGE PASSWORD] Lỗi: $e");
      return {"success": false, "message": "Lỗi mạng: $e"};
    }
  }

  // ---------------- GET USER ID ----------------
  Future<String?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return null;

    final decoded = JwtDecoder.decode(token);
    final userId = decoded['userId'];
    print("👤 [USER INFO] UserId lấy từ token: $userId");
    return userId;
  }
}
