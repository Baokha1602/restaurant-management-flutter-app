import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../models/customer.dart';
import '../models/customer_rank.dart';
import 'token_service.dart';

class CustomerService {
  final TokenService _tokenService = TokenService();
  static String get _baseUrl => "${Config_URL.baseApiUrl}/CustomerApi";
  static String get BASE_URL => "${Config_URL.baseApiUrl}/CustomerRankApi";
  static String get apiUrl => "${Config_URL.baseApiUrl}/AccountApi";
  /// Lấy tất cả khách hàng (dành cho admin)
  Future<List<CustomerDTO>> getAllCustomers({
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    final token = await _tokenService.getToken();
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final url = Uri.parse("$_baseUrl/GetAllCustomer")
        .replace(queryParameters: queryParams);

    //debugPrint('[CustomerService] GET All URL: $url');

    final response = await http.get(
      url,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    //debugPrint('[CustomerService] StatusCode: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => CustomerDTO.fromJson(e)).toList();
    } else {
      throw Exception(
          'Lỗi load khách hàng: ${response.statusCode} ${response.body}');
    }
  }

  ///  Lấy chi tiết khách hàng
  Future<CustomerDTO> getCustomerById({String? userId}) async {
    final token = await _tokenService.getToken();

    // Nếu không có userId → lấy từ token
    if (userId == null || userId.isEmpty) {
      userId = await _tokenService.getUserIdFromToken();
      if (userId == null || userId.isEmpty) {
        throw Exception('Không tìm thấy userId để lấy thông tin.');
      }
    }

    final url = Uri.parse("$_baseUrl/GetCustomerById")
        .replace(queryParameters: {'userId': userId});

    //debugPrint('[CustomerService] 🔵 URL: $url');

    final response = await http.get(url, headers: {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json',
    });

    // debugPrint('[CustomerService] 🟡 Status: ${response.statusCode}');
    // debugPrint('[CustomerService] 🟡 Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final data = jsonData['customer'] ?? jsonData;
      return CustomerDTO.fromJson(data);
    } else {
      throw Exception(
          'Không thể lấy thông tin khách hàng: ${response.statusCode}');
    }
  }

  /// Lấy danh sách hạng (rank)
  Future<List<CustomerRank>> getRanks() async {
    final token = await _tokenService.getToken();
    final url = Uri.parse(BASE_URL);

    debugPrint('🔹 Gọi API lấy hạng: $url');

    final response = await http.get(
      url,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    debugPrint('🔹 Status: ${response.statusCode}');
    debugPrint('🔹 Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => CustomerRank.fromJson(e)).toList();
    } else {
      throw Exception('Không thể lấy danh sách hạng: ${response.statusCode}');
    }
  }

  /// Cập nhật khách hàng (PUT + upload ảnh)
  /// Nếu customer.customerId null → lấy userId từ token (user bình thường)
  Future<void> updateCustomer(CustomerDTO customer, File? selectedImage) async {
    final token = await _tokenService.getToken();

    // Lấy userId
    String? userId = customer.customerId;
    if (userId == null || userId.isEmpty) {
      userId = await _tokenService.getUserIdFromToken();
      if (userId == null || userId.isEmpty) {
        throw Exception('Không tìm thấy userId để cập nhật.');
      }
    }

    final url = Uri.parse('$_baseUrl/UpdateCustomer?userId=$userId');
    //debugPrint('[CustomerService] 🟡 PUT URL: $url');

    try {
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'customerId': userId,
        'name': customer.name,
        'email': customer.email,
        'phoneNumber': customer.phoneNumber,
        'gender': customer.gender.toString(),
        'dateOfBirth': customer.dateOfBirth ?? '',
        'point': (customer.point ?? 0).toString(),
        'rankId': (customer.rankId ?? 1).toString(),
      });

      if (selectedImage != null && selectedImage.existsSync()) {
        request.files.add(await http.MultipartFile.fromPath(
          'urlImage',
          selectedImage.path,
        ));
        //debugPrint('[CustomerService] Uploading image: ${selectedImage.path}');
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // debugPrint('[CustomerService] ✅ Status: ${streamedResponse.statusCode}');
      // debugPrint('[CustomerService] ✅ Body: $responseBody');

      if (streamedResponse.statusCode != 200) {
        throw Exception(
            'Cập nhật thất bại: ${streamedResponse.statusCode}\n$responseBody');
      }
    } catch (e, s) {
      // debugPrint('[CustomerService] ❌ Exception: $e');
      // debugPrint('[CustomerService] ❌ Stacktrace: $s');
      rethrow;
    }
  }
  // ---------------- REGISTER ----------------
  /// Đăng ký khách hàng mới — dùng chính email làm username
  Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNumber,
    required String dateOfBirth,
    required int gender,
    required int rankId,
    required String email,
    required String password,
    required String confirmPassword,
    File? imageFile,
  }) async {
    final url = Uri.parse('$apiUrl/Register');

    try {
      var request = http.MultipartRequest('POST', url);

      // 🟢 Dùng email làm username
      final normalizedEmail = email.toUpperCase();

      request.fields['Name'] = name;
      request.fields['PhoneNumber'] = phoneNumber;
      request.fields['DateOfBirth'] = dateOfBirth;
      request.fields['Gender'] = gender.toString();
      request.fields['RankId'] = rankId.toString();
      request.fields['Email'] = email;
      request.fields['NormalizedEmail'] = normalizedEmail;
      request.fields['UserName'] = email;
      request.fields['NormalizedUserName'] = normalizedEmail;
      request.fields['Password'] = password;
      request.fields['ConfirmPassword'] = confirmPassword;

      if (imageFile != null && await imageFile.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('ImageFile', imageFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("🔹 Status Code: ${response.statusCode}");
      debugPrint("🔹 Response Body: ${response.body}");

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
      return {
        "statusCode": 500,
        "success": false,
        "body": {"message": e.toString()},
      };
    }
  }

  /// 🧱 Khóa tài khoản (vô hiệu hóa)
  Future<bool> lockUser(String userId) async {
    final token = await _tokenService.getToken();
    // 🔹 Dùng đúng API và method PUT
    final url = Uri.parse('$_baseUrl/LockUser/$userId');

    final response = await http.put(
      url,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    debugPrint('🔴 LockUser ${response.statusCode}: ${response.body}');
    return response.statusCode == 200;
  }

  /// 🔓 Mở khóa tài khoản
  Future<bool> unlockUser(String userId) async {
    final token = await _tokenService.getToken();
    final url = Uri.parse('$_baseUrl/UnlockUser/$userId');

    final response = await http.put(
      url,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    debugPrint('🟢 UnlockUser ${response.statusCode}: ${response.body}');
    return response.statusCode == 200;
  }
  Future<List<CustomerDTO>> getLockedCustomers() async {
    final token = await _tokenService.getToken();
    final url = Uri.parse("${Config_URL.baseApiUrl}/CustomerApi/GetLockedCustomers");

    final response = await http.get(url, headers: {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => CustomerDTO.fromJson(e)).toList();
    } else {
      throw Exception("Không thể tải danh sách tài khoản bị vô hiệu hoá");
    }
  }


}