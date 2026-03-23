import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../models/customer_rank.dart';
import 'token_service.dart';

class CustomerRankService {
  static String get BASE_URL => "${Config_URL.baseApiUrl}/CustomerRankApi";
  final TokenService _tokenService;

  CustomerRankService(this._tokenService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      // Xử lý trường hợp không có token
      throw Exception('Authorization token not found.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<CustomerRank>> getAllCustomerRanks() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(BASE_URL),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return customerRankFromJson(response.body);
    } else {
      // Có thể xử lý các mã lỗi cụ thể, ví dụ 401 Unauthorized
      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      }
      throw Exception('Failed to load customer ranks: ${response.statusCode}');
    }
  }

  Future<bool> createCustomerRank(CustomerRank rank) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(BASE_URL),
      headers: headers,
      body: jsonEncode(rank.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateCustomerRank(CustomerRank rank) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse(BASE_URL),
      headers: headers,
      body: jsonEncode(rank.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteCustomerRank(int rankId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$BASE_URL/$rankId'),
      headers: headers,
    );
    return response.statusCode == 200;
  }
}