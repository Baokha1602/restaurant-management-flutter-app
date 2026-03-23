import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';

class MenuAddScreen extends StatefulWidget {
  const MenuAddScreen({super.key});

  @override
  State<MenuAddScreen> createState() => _MenuAddScreenState();
}

class _MenuAddScreenState extends State<MenuAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _detailCtrl = TextEditingController();

  bool _isSaving = false;
  late final String apiUrl;
  late final String categoryUrl;

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;

  // ✅ Danh sách ảnh được chọn
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/MenuApi";
    categoryUrl = "${Config_URL.baseApiUrl}/MenuCategoryApi";
    _fetchCategories();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _fetchCategories() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse(categoryUrl),
        headers: {'Authorization': token},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _categories = data
                .map<Map<String, dynamic>>((e) => {
              "id": e["menuCategoryId"],
              "name": e["menuCategoryName"],
            })
                .toList();
          });
        }
      } else {
        _showSnack("Không tải được loại món (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi khi tải loại món: $e");
    }
  }

  // ✅ Chọn nhiều ảnh
  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(images);
      });
    }
  }

  // ✅ Gửi dữ liệu qua multipart/form-data
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnack("Vui lòng chọn loại món ăn");
      return;
    }

    if (_selectedImages.isEmpty) {
      _showSnack("Vui lòng chọn ít nhất 1 ảnh món ăn");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final uri = Uri.parse(apiUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = token;

      request.fields['menuName'] = _nameCtrl.text.trim();
      request.fields['detail'] = _detailCtrl.text.trim();
      request.fields['menuCategoryId'] = _selectedCategoryId.toString();

      for (var img in _selectedImages) {
        request.files.add(await http.MultipartFile.fromPath('images', img.path));
      }

      final res = await request.send();

      if (res.statusCode == 200) {
        _showSnack("✅ Thêm món mới thành công!");
        Navigator.pop(context, true);
      } else {
        final body = await res.stream.bytesToString();
        try {
          final err = jsonDecode(body);
          if (err is Map && err.containsKey('message')) {
            _showSnack("⚠️ ${err['message']}");
          } else {
            _showSnack("Lỗi ${res.statusCode}: $body");
          }
        } catch (_) {
          _showSnack("Lỗi ${res.statusCode}");
        }
      }
    } catch (e) {
      _showSnack("Lỗi: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
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
        title: const Text("Thêm món ăn",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.restaurant_menu_rounded,
                  size: 90, color: Colors.orange.shade300),
              const SizedBox(height: 18),
              Text(
                "Nhập thông tin món ăn mới",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),

              // 🧾 Tên món
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputStyle("Tên món ăn", Icons.fastfood),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Không được để trống tên món";
                  }
                  if (v.trim().length < 3) {
                    return "Tên món phải từ 3 ký tự trở lên";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 🧾 Dropdown loại món ăn
              InputDecorator(
                decoration: _inputStyle("Loại món ăn", Icons.category),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCategoryId,
                    hint: const Text("Chọn loại món ăn"),
                    isExpanded: true,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat['id'],
                        child: Text(cat['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🧾 Mô tả
              TextFormField(
                controller: _detailCtrl,
                decoration: _inputStyle("Mô tả chi tiết", Icons.description),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // 📸 Chọn ảnh
              Text("Ảnh món ăn (ảnh đầu tiên là ảnh chính):",
                  style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedImages.map((img) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(img.path),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedImages.remove(img));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  )),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.orange.withOpacity(0.1),
                        border:
                        Border.all(color: Colors.orangeAccent, width: 1.2),
                      ),
                      child: const Icon(Icons.add_a_photo,
                          color: Colors.orange, size: 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 🧾 Nút lưu
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSaving ? "Đang lưu..." : "Lưu món ăn",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
