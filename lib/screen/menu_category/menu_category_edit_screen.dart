import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:restaurantmanager/config/config_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuCategoryEditScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  const MenuCategoryEditScreen({super.key, required this.category});

  @override
  State<MenuCategoryEditScreen> createState() => _MenuCategoryEditScreenState();
}

class _MenuCategoryEditScreenState extends State<MenuCategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category['menuCategoryName']);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('jwt_token');
    if (t == null) return null;
    return t.startsWith('Bearer ') ? t : 'Bearer $t';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = await _getToken();
    if (token == null) return;

    final uri = Uri.parse("${Config_URL.baseApiUrl}/MenuCategoryApi");
    final body = jsonEncode({
      "menuCategoryId": widget.category['menuCategoryId'],
      "menuCategoryName": _nameCtrl.text,
    });

    try {
      final res = await http.put(uri,
          headers: {"Authorization": token, "Content-Type": "application/json"},
          body: body);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("✅ Cập nhật thành công!")));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Cập nhật thất bại: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text("Chỉnh sửa loại món", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.edit_note_rounded, size: 80, color: Colors.orange.shade300),
              const SizedBox(height: 20),
              Text(
                "Cập nhật thông tin loại món ăn",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration("Tên loại món ăn", Icons.restaurant_menu_outlined),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập tên loại món" : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Lưu thay đổi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
