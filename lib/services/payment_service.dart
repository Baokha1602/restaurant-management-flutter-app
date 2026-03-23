import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class PaymentService {
  /// 🔹 Lấy token JWT từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      debugPrint("⚠️ [PaymentService] Không tìm thấy JWT token trong SharedPreferences");
      return null;
    }

    return token;
  }

  /// 🔹 Cập nhật phương thức thanh toán và tổng tiền
  Future<Map<String, dynamic>> updatePaymentInfo({
    required int orderId,
    required double total,
    required String paymentMethod,
    String? discountId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Không tìm thấy token");

      final url = Uri.parse('${Config_URL.baseApiUrl}/OrderApi/UpdatePaymentMethodandTotal');
      final body = jsonEncode({
        "orderId": orderId,
        "total": total,
        "discountId": discountId ?? "",
        "paymentMethod": paymentMethod,
      });

      debugPrint("📤 [PaymentService] Gửi updatePaymentInfo tới: $url");
      debugPrint("📦 Body: $body");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint("✅ [PaymentService] Cập nhật thanh toán thành công!");
        return jsonDecode(response.body);
      } else {
        debugPrint("❌ [PaymentService] Lỗi cập nhật thanh toán: ${response.statusCode}");
        return {"isSuccess": false, "message": "Cập nhật thất bại"};
      }
    } catch (e) {
      debugPrint("🚨 [PaymentService] Lỗi updatePaymentInfo: $e");
      return {"isSuccess": false, "message": "Không thể cập nhật thanh toán"};
    }
  }

  /// 🔹 Tạo URL thanh toán MoMo
  Future<String?> createMomoPayment({
    required int orderId,
    required String fullName,
    required double amount,
    // Bạn có thể truyền returnUrl vào đây nếu muốn linh động,
    // hoặc hardcode cứng bên dưới nếu chỉ có 1 app.
    String returnUrl = "hutechrestaurant://momo/payment",
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Không tìm thấy token");

      final url = Uri.parse('${Config_URL.baseApiUrl}/PaymentApi/CreatePaymentMomo');

      // CẬP NHẬT BODY TẠI ĐÂY
      final body = jsonEncode({
        "fullName": fullName,
        "orderId": orderId.toString(),
        "orderInfomation": "Thanh toán đơn hàng #$orderId từ HutechRestaurant",
        "amount": amount,
        "returnUrl": returnUrl, // <--- Đã thêm trường returnUrl
      });

      debugPrint("📤 [MoMo] Gửi yêu cầu tạo URL: $url");
      debugPrint("📦 Body: $body");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      debugPrint("📥 [MoMo] Phản hồi: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? paymentUrl;

        // Logic lấy link thanh toán (giữ nguyên như cũ)
        if (data["url"] is String) {
          paymentUrl = data["url"];
        } else if (data["url"] is Map && data["url"]["result"] != null) {
          paymentUrl = data["url"]["result"];
        } else if (data["result"] is String) {
          paymentUrl = data["result"];
        }

        debugPrint("✅ [MoMo] Order #$orderId (${amount.toStringAsFixed(0)}đ) -> URL: $paymentUrl");
        return paymentUrl;
      } else {
        debugPrint("❌ [MoMo] Lỗi tạo URL, mã trạng thái: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("🚨 [MoMo] Lỗi createMomoPayment: $e");
      return null;
    }
  }

  /// 🔹 Lấy danh sách đơn hàng thanh toán bằng tiền mặt (Admin)
  Future<List<Map<String, dynamic>>> getOrdersPayByCash() async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⚠️ [Payment] Không tìm thấy token trong SharedPreferences");
        return [];
      }

      final url = Uri.parse('${Config_URL.baseApiUrl}/OrderApi/GetOrdersPayByCash');
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("📦 [Payment] Status: ${response.statusCode}");
      debugPrint("🧾 [Payment] Body: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint("✅ [Payment] Nhận ${data.length} đơn hàng tiền mặt");
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        debugPrint("❌ [Payment] Lỗi khi lấy đơn: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("🚨 [Payment] Exception: $e");
      return [];
    }
  }

  /// 🔹 Xác nhận đơn hàng đã thanh toán tiền mặt
  Future<Map<String, dynamic>> confirmOrderPayByCash(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⚠️ [Payment] Không tìm thấy token trong SharedPreferences");
        return {"isSuccess": false, "message": "Không có token"};
      }

      final url = Uri.parse('${Config_URL.baseApiUrl}/PaymentApi/ConfirmOrderPayByCash?orderId=$orderId');
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("📤 [ConfirmCash] ${response.statusCode}: ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"isSuccess": false, "message": "Lỗi ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("🚨 [ConfirmCash] Exception: $e");
      return {"isSuccess": false, "message": "Lỗi kết nối"};
    }
  }
}
