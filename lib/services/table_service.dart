import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/table.dart';
import '../utils/get_headers.dart';
import '../config/config_url.dart';

class TableService {
  Future<List<TableModel>> getTables() async {
    final response = await http.get(
      Uri.parse('${Config_URL.baseApiUrl}/TableApi'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TableModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải danh sách bàn');
    }
  }

  Future<void> createTable(String tableName, int numberOfSeats) async {
    final response = await http.post(
      Uri.parse('${Config_URL.baseApiUrl}/TableApi'),
      headers: await getHeaders(),
      body: jsonEncode({
        'tableName': tableName,
        'numberOfSeats': numberOfSeats,
        'tableStatus': 'Trống',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi tạo bàn');
    }
  }

  Future<void> updateTable(TableModel table) async {
    final response = await http.put(
      Uri.parse('${Config_URL.baseApiUrl}/TableApi'),
      headers: await getHeaders(),
      body: jsonEncode(table.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi cập nhật bàn');
    }
  }

  // ✅ Đã chỉnh để trả về message từ server
  Future<String> deleteTable(int tableId) async {
    final response = await http.delete(
      Uri.parse('${Config_URL.baseApiUrl}/TableApi/$tableId'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      // ✅ Trả message JSON để frontend đọc "Không thể xóa bàn đang sử dụng"
      return response.body;
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy bàn cần xóa');
    } else if (response.statusCode == 400) {
      throw Exception('Yêu cầu không hợp lệ');
    } else {
      throw Exception('Lỗi khi xóa bàn (${response.statusCode})');
    }
  }

  Future<void> createQr(int tableId) async {
    final response = await http.get(
      Uri.parse('${Config_URL.baseApiUrl}/TableApi/CreateQR?tableId=$tableId'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi khi tạo mã QR');
    }
  }
}
