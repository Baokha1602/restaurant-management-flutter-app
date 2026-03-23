import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import '../models/menu_order.dart';

class MenuService {
  final String _menuEndpoint =
      "${Config_URL.baseApiUrl}/MenuApi/GetAvailableMenusByCategory";
  final String _categoryEndpoint = "${Config_URL.baseApiUrl}/MenuCategoryApi";

  /// 🟧 Lấy danh sách loại món ăn (thêm mục "Tất cả")
  Future<List<Map<String, dynamic>>> getMenuCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token");

      // 🟢 Log thông tin trước khi gửi request
      print("📡 [MenuService] Gửi request lấy danh mục món ăn:");
      print("🔹 Endpoint: $_categoryEndpoint");
      print("🔹 Có token: ${token != null && token.isNotEmpty}");
      print("🔹 Header: { Content-Type: application/json, Authorization: Bearer [HIDDEN] }");

      final response = await http.get(
        Uri.parse(_categoryEndpoint),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      // 🟠 Log kết quả phản hồi
      print("📥 [MenuService] Nhận phản hồi từ API:");
      print("🔹 Status code: ${response.statusCode}");
      if (response.body.isNotEmpty && response.body.length < 1000) {
        print("🔹 Response body: ${response.body}");
      } else {
        print("🔹 Response body quá dài, chỉ in tóm tắt (${response.body.length} ký tự)");
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // 🟢 Log số lượng danh mục nhận được
        print("✅ [MenuService] Nhận được ${data.length} danh mục.");

        // Thêm mục "Tất cả"
        final List<Map<String, dynamic>> categories = [
          {"menuCategoryId": null, "menuCategoryName": "Tất cả"},
          ...data.map((e) => {
            "menuCategoryId": e["menuCategoryId"],
            "menuCategoryName": e["menuCategoryName"]
          }),
        ];

        // 🟢 Log danh sách cuối cùng
        print("📋 Danh mục sau khi thêm 'Tất cả': ${categories.map((e) => e["menuCategoryName"]).join(', "')}");

        return categories;
      } else {
        print("❌ [MenuService] Gọi API thất bại: ${response.statusCode} - ${response.body}");
        throw Exception(
            "Không thể tải danh mục: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("🚨 [MenuService] Lỗi khi tải danh mục: $e");
      throw Exception("Lỗi khi tải danh mục: $e");
    }
  }

  /// 🟧 Lấy danh sách món ăn theo loại (nếu null thì lấy tất cả)
  Future<List<MenuOrderModel>> getAvailableMenus({int? categoryId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token");

      String url = _menuEndpoint;
      if (categoryId != null) {
        url = "$_menuEndpoint?categoryId=$categoryId";
      }

      print("📡 [MenuService] Gửi request lấy menu:");
      print("🔹 URL: $url");
      print("🔹 Có token: ${token != null && token.isNotEmpty}");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      print("📥 [MenuService] Phản hồi lấy menu: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("✅ [MenuService] Nhận được ${data.length} món ăn.");
        return data.map((item) => MenuOrderModel.fromJson(item)).toList();
      } else {
        print("❌ [MenuService] Gọi API thất bại: ${response.statusCode}");
        throw Exception(
            "Không thể tải menu: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("🚨 [MenuService] Lỗi khi tải menu: $e");
      throw Exception("Lỗi khi tải menu: $e");
    }
  }
}
