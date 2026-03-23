import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';
import 'package:restaurantmanager/models/inventory_model.dart';

class InventoryEditScreen extends StatefulWidget {
  final Inventory inventory;
  const InventoryEditScreen({super.key, required this.inventory});

  @override
  State<InventoryEditScreen> createState() => _InventoryEditScreenState();
}

class _InventoryEditScreenState extends State<InventoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _unitCtrl;
  late TextEditingController _quantityCtrl;
  bool _isSaving = false;

  late final String apiUrl;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/InventoryApi";
    _unitCtrl = TextEditingController(text: widget.inventory.unit);
    _quantityCtrl = TextEditingController(text: widget.inventory.quantity.toString());
  }

  @override
  void dispose() {
    _unitCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final token = await _getBearerToken();
      if (token == null) return;

      // ✅ Dữ liệu gửi đi — không cần foodSizeId nữa
      final body = jsonEncode({
        "inventoryId": widget.inventory.inventoryId,
        "unit": _unitCtrl.text.trim(),
        "quantity": int.parse(_quantityCtrl.text.trim()),
      });

      final uri = Uri.parse("$apiUrl/${widget.inventory.inventoryId}");
      final res = await http.put(
        uri,
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: body,
      );

      print("📤 Body gửi: $body");
      print("📥 Response: ${res.statusCode} - ${res.body}");

      // ✅ Phân tích kết quả backend trả về
      if (res.statusCode == 200) {
        try {
          final json = jsonDecode(res.body);
          final isSuccess = json['isSuccess'] ?? false;
          final msg = json['message'] ?? "Cập nhật tồn kho";
          if (isSuccess) {
            _showSnack("✅ $msg", success: true);
            Navigator.pop(context, true);
          } else {
            _showSnack("⚠️ $msg", success: false);
          }
        } catch (_) {
          _showSnack("✅ Cập nhật thành công!", success: true);
          Navigator.pop(context, true);
        }
      } else if (res.statusCode == 401) {
        _showSnack("Phiên đăng nhập hết hạn hoặc không có quyền (401)", success: false);
      } else {
        // 🔥 Nếu backend trả lỗi có message
        try {
          final json = jsonDecode(res.body);
          _showSnack("⚠️ ${json['message'] ?? 'Lỗi cập nhật (${res.statusCode})'}", success: false);
        } catch (_) {
          _showSnack("Lỗi cập nhật (${res.statusCode})", success: false);
        }
      }
    } catch (e) {
      _showSnack("Lỗi: $e", success: false);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ✅ SnackBar tiện dụng
  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text(
          "Chỉnh sửa tồn kho",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: mainColor,
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.inventory_2_outlined, size: 90, color: Colors.orange.shade300),
              const SizedBox(height: 16),
              Text(
                "Cập nhật thông tin tồn kho",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 35),

              // 🧾 Món ăn (read-only)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.inventory.menuName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🧾 Kích cỡ (read-only)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rice_bowl, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.inventory.foodSizeName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // ⚙️ Đơn vị
              TextFormField(
                controller: _unitCtrl,
                decoration: _inputStyle("Đơn vị (VD: Ly, Dĩa...)", Icons.scale),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Không được để trống đơn vị"
                    : null,
              ),
              const SizedBox(height: 20),

              // 🔢 Số lượng
              TextFormField(
                controller: _quantityCtrl,
                decoration: _inputStyle("Số lượng tồn", Icons.numbers),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Không được để trống số lượng";
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return "Số lượng không hợp lệ";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // 🔘 Nút Lưu
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSaving ? "Đang lưu..." : "Lưu thay đổi",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
