import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';

  // Lưu token vào SharedPreferences
  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    //print('Token saved: $token'); // Để kiểm tra trong debug
  }

  // Lấy token từ SharedPreferences
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_tokenKey);
    //print('Token retrieved: $token'); // Để kiểm tra trong debug
    return token;
  }

  // Xóa token (khi đăng xuất)
  Future<void> deleteToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    //print('Token deleted.'); // Để kiểm tra trong debug
  }
  ///  Giải mã token để lấy userId
  Future<String?> getUserIdFromToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      Map<String, dynamic> decoded = JwtDecoder.decode(token);
      // Kiểm tra key chính xác mà backend dùng trong claim
      return decoded['UserId'] ?? decoded['userId'];
    } catch (e) {
      //print('[TokenService] ❌ Lỗi decode token: $e');
      return null;
    }
  }
}