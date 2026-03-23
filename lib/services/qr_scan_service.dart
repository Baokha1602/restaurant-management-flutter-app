import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class QrScanService {

  /// 🔍 Gửi request xác thực QR và trả về QrResolveResult
  Future<void> validTableTokenFromQr(String qrData) async{
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    final baseUrl = Config_URL.baseApiUrl; // ✅ .env
    const endpoint = "/TableApi/ValidTableToken";

    if (jwtToken == null) {
      throw Exception("❌ Chưa đăng nhập – thiếu JWT token");
    }

    // ✅ Parse token từ QR
    final uri = Uri.parse(qrData);
    final tableToken = uri.queryParameters['token'];

    if (tableToken == null || tableToken.isEmpty) {
      throw Exception("❌ QR không hợp lệ – không tìm thấy token");
    }

    final url = Uri.parse("$baseUrl$endpoint?token=$tableToken");

    print("==========================================");
    print("📷 [QRScanService] Validate Table Token");
    print("🌐 URL: $url");
    print("🔑 TableToken: $tableToken");
    print("🪪 JWT (rút gọn): ${jwtToken.substring(0, 20)}...");
    print("==========================================");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $jwtToken",
      },
    );

    print("📡 [Response] Status: ${response.statusCode}");
    print("📩 Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final isValid = data["isValid"];
      final tableId = data["tableId"];
      final message = data["message"];

      if (isValid == true && tableId != null) {
        // ✅ Lưu vào SharedPreferences
        await prefs.setInt("table_id", tableId);
        await prefs.setString("table_token", tableToken);

        print("✅ [QRScanService] Token bàn hợp lệ");
        print("🪑 Table ID: $tableId");
        print("💾 Đã lưu 'table_id' & 'table_token'");
      } else {
        throw Exception("⚠️ Token không hợp lệ: $message");
      }
    } else {
      throw Exception(
        "❌ Validate token thất bại (${response.statusCode}): ${response.body}",
      );
    }

    // ✅ Debug lại SharedPreferences
    final savedTableId = prefs.getInt("table_id");
    print("🧪 [SharedPreferences] table_id hiện tại: $savedTableId");
  }

}
