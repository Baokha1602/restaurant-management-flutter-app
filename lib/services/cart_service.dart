import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class CartService {
  final String _createCartEndpoint = "/CartApi/Create";
  final String _addToCartEndpoint = "/CartApi/AddToCart";
  final String _removeFromCartEndpoint = "/CartApi/RemoveToCart";

  /// 🧾 Tạo giỏ hàng mặc định sau khi xác thực bàn
  Future<void> createCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userId = prefs.getString('user_id');
    final tableId = prefs.getInt('table_id');
    final baseUrl = Config_URL.baseApiUrl; // ✅ Lấy từ .env

    if (token == null || userId == null || tableId == null) {
      throw Exception("Thiếu thông tin tạo giỏ hàng (token/user/table).");
    }

    final url = Uri.parse("$baseUrl$_createCartEndpoint");
    final body = jsonEncode({
      "CartStatus": "Chưa xác nhận",
      "CustomerId": userId,
      "TableId": tableId
    });

    print("==========================================");
    print("🛒 [CartService] Gửi POST đến: $url");
    print("📦 Body: $body");
    print("🔑 Token (rút gọn): ${token.length > 20 ? token.substring(0, 20) + '...' : token}");
    print("==========================================");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: body,
    );

    print("📡 [Response] Status: ${response.statusCode}");
    print("📩 Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      final cartId = responseData["cartId"];
      final message = responseData["message"];
      final isSuccess = responseData["isSuccess"];

      if (isSuccess == true && cartId != null) {
        await prefs.setInt('cartId', cartId);
        print("✅ [CartService] Tạo giỏ hàng thành công!");
        print("🆔 Cart ID: $cartId");
        print("💾 Đã lưu vào SharedPreferences với key 'cartId'");
      } else {
        print("⚠️ [CartService] Tạo giỏ hàng thất bại hoặc phản hồi sai định dạng.");
        print("Phản hồi: $responseData");
      }
    } else {
      print("⚠️ [CartService] Lỗi tạo giỏ hàng: ${response.statusCode}");
      throw Exception("Không thể tạo giỏ hàng: ${response.body}");
    }

    // ✅ Kiểm tra lại giá trị đã lưu
    final savedCartId = prefs.getInt('cartId');
    print("📦 [SharedPreferences] Giá trị hiện tại của cartId: $savedCartId");
  }

  /// 🟢 Thêm món vào giỏ hàng
  Future<bool> addToCart(int foodSizeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final cartId = prefs.getInt('cartId');
    final baseUrl = Config_URL.baseApiUrl;

    if (token == null || cartId == null) {
      print("🚨 [CartService] Thiếu token hoặc cartId khi gọi AddToCart.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_addToCartEndpoint?foodSizeId=$foodSizeId&cartId=$cartId");
    print("📡 [CartService] Gọi AddToCart: $url");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("📥 [CartService] AddToCart Status: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ [CartService] Thêm món vào giỏ hàng thành công!");
      return true;
    } else {
      print("⚠️ [CartService] Thêm món thất bại: ${response.statusCode}");
      return false;
    }
  }

  /// 🔴 Xóa món khỏi giỏ hàng
  Future<bool> removeFromCart(int foodSizeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final cartId = prefs.getInt('cartId');
    final baseUrl = Config_URL.baseApiUrl;

    if (token == null || cartId == null) {
      print("🚨 [CartService] Thiếu token hoặc cartId khi gọi RemoveToCart.");
      return false;
    }

    final url = Uri.parse("$baseUrl$_removeFromCartEndpoint?foodSizeId=$foodSizeId&cartId=$cartId");
    print("📡 [CartService] Gọi RemoveToCart: $url");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("📥 [CartService] RemoveToCart Status: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ [CartService] Xóa món khỏi giỏ hàng thành công!");
      return true;
    } else {
      print("⚠️ [CartService] Xóa món thất bại: ${response.statusCode}");
      return false;
    }
  }
  Future<Map<String, dynamic>?> getCartSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final cartId = prefs.getInt('cartId');
    final baseUrl = Config_URL.baseApiUrl;

    if (token == null || cartId == null) {
      print("🚨 [CartService] Thiếu token hoặc cartId khi gọi getCartSummary.");
      return null;
    }

    final url = Uri.parse("$baseUrl/CartApi/Summary/$cartId");
    print("📡 [CartService] Gọi API lấy thông tin giỏ hàng: $url");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("📥 [CartService] Summary Status: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "cartId": data["cartId"],
        "distinctFoodCount": data["distinctFoodCount"],
        "totalPrice": data["totalPrice"]
      };
    } else {
      print("⚠️ [CartService] Lỗi lấy thông tin giỏ hàng: ${response.statusCode}");
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final baseUrl = Config_URL.baseApiUrl;

    if (token == null) {
      print("🚨 [CartService] Thiếu token khi gọi getCartItems.");
      return [];
    }

    final url = Uri.parse("$baseUrl/CartApi/GetCartItem");
    print("📡 [CartService] Gọi API lấy danh sách món trong giỏ: $url");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("✅ [CartService] Nhận ${data.length} món trong giỏ.");
      return List<Map<String, dynamic>>.from(data);
    } else {
      print("⚠️ [CartService] Lỗi lấy món: ${response.statusCode}");
      return [];
    }
  }

  Future<bool> createOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final baseUrl = Config_URL.baseApiUrl;

    if (token == null) return false;

    final url = Uri.parse("$baseUrl/OrderApi/CreateOrder");
    print("🧾 [CartService] Gửi yêu cầu tạo đơn hàng: $url");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ [CartService] Tạo đơn hàng thành công!");
      return true;
    } else {
      print("❌ [CartService] Lỗi tạo đơn hàng: ${response.body}");
      return false;
    }
  }

}