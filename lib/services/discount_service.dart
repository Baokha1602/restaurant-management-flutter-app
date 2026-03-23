import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class DiscountService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// 🔹 Gọi API lấy danh sách mã giảm giá chưa sử dụng
  Future<List<Map<String, dynamic>>> getAvailableDiscounts() async {
    try {
      final token = await _getToken();

      if (token == null) {
        debugPrint("⚠️ [Discount] Không tìm thấy token trong SharedPreferences");
        return [];
      }

      final url = Uri.parse('${Config_URL.baseApiUrl}/DiscountCustomerApi');
      debugPrint("🌐 [Discount] Gọi API: $url");
      debugPrint("🔑 [Discount] Token: $token");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("📦 [Discount] Status: ${response.statusCode}");
      debugPrint("🧾 [Discount] Body: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint("✅ [Discount] Nhận ${data.length} mã giảm giá khả dụng");
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrint("❌ [Discount] Lỗi: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("🚨 [Discount] Exception: $e");
      return [];
    }
  }
}
