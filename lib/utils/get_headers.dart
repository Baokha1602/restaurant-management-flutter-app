import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token != null) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  } else {
    return {
      'Content-Type': 'application/json',
    };
  }
}
