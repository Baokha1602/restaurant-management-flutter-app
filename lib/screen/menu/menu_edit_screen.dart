import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';

class MenuEditScreen extends StatefulWidget {
  final Map<String, dynamic> menu;
  const MenuEditScreen({super.key, required this.menu});

  @override
  State<MenuEditScreen> createState() => _MenuEditScreenState();
}

class _MenuEditScreenState extends State<MenuEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _detailCtrl;

  bool _isSaving = false;
  late final String apiUrl;
  late final String categoryUrl;

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;

  List<String> _oldImages = [];
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  String? _mainImageUrl; // có thể là URL (ảnh cũ) hoặc local path (ảnh mới)

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/MenuApi";
    categoryUrl = "${Config_URL.baseApiUrl}/MenuCategoryApi";
    _nameCtrl = TextEditingController(text: widget.menu['menuName']);
    _detailCtrl = TextEditingController(text: widget.menu['detail'] ?? '');
    _oldImages = (widget.menu['imageUrls'] as List?)?.cast<String>() ?? [];
    _mainImageUrl = widget.menu['mainImageUrl'];
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

      final res = await http.get(Uri.parse(categoryUrl), headers: {'Authorization': token});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _categories = data.map<Map<String, dynamic>>((e) => {
              "id": e["menuCategoryId"],
              "name": e["menuCategoryName"],
            }).toList();

            final match = _categories.firstWhere(
                  (c) => c['name'] == widget.menu['menuCategoryName'],
              orElse: () => _categories.first,
            );
            _selectedCategoryId = match['id'];
          });
        }
      } else {
        _showSnack("Không tải được loại món (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi khi tải loại món: $e");
    }
  }

  // Chọn thêm ảnh
  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
        // Nếu chưa có ảnh chính (đã xóa ảnh cũ) thì ảnh mới đầu tiên sẽ là ảnh chính
        if (_mainImageUrl == null && _newImages.isNotEmpty) {
          _mainImageUrl = _newImages.first.path; // local path
        }
      });
    }
  }

  // Đặt ảnh cũ làm ảnh chính (URL)
  void _setAsMain(String url) {
    setState(() {
      _mainImageUrl = url;
      if (!_oldImages.contains(url)) _oldImages.add(url);
    });
  }

  // Xem ảnh lớn + đặt làm chính
  void _previewImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(Config_URL.baseUrl + url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    icon: const Icon(Icons.star, color: Colors.white),
                    label: const Text("Đặt làm ảnh chính", style: TextStyle(color: Colors.white)),
                    onPressed: () { Navigator.pop(context); _setAsMain(url); },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text("Đóng", style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Xóa ảnh cũ
  void _removeOldImage(String url) {
    setState(() {
      _oldImages.remove(url);
      if (_mainImageUrl == url) _mainImageUrl = null;
    });
  }

  // Xóa ảnh mới
  void _removeNewImage(XFile img) {
    setState(() {
      _newImages.remove(img);
      if (_mainImageUrl == img.path) {
        _mainImageUrl = _newImages.isNotEmpty ? _newImages.first.path : null;
      }
    });
  }

  // Gửi cập nhật
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) { _showSnack("Vui lòng chọn loại món ăn"); return; }

    setState(() => _isSaving = true);
    try {
      final token = await _getToken(); if (token == null) return;

      final id = widget.menu['menuId'];
      final uri = Uri.parse("$apiUrl/$id");
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = token;

      request.fields['menuId'] = id.toString();
      request.fields['menuName'] = _nameCtrl.text.trim();
      request.fields['detail'] = _detailCtrl.text.trim();
      request.fields['menuCategoryId'] = _selectedCategoryId.toString();

      // Nếu main là local path (ảnh mới), đảm bảo file đó nằm ở vị trí đầu tiên trong list upload
      if (_mainImageUrl != null && _newImages.any((x) => x.path == _mainImageUrl)) {
        final idx = _newImages.indexWhere((x) => x.path == _mainImageUrl);
        if (idx > 0) {
          final mainImg = _newImages.removeAt(idx);
          _newImages.insert(0, mainImg);
        }
      }

      // existingImages: { keep: [url...], main: "<url hoặc local-path>" }
      final keepData = { "keep": _oldImages, "main": _mainImageUrl };
      request.fields['existingImages'] = jsonEncode(keepData);

      for (var img in _newImages) {
        request.files.add(await http.MultipartFile.fromPath('images', img.path));
      }

      final res = await request.send();
      if (res.statusCode == 200) {
        _showSnack("✅ Cập nhật món ăn thành công!");
        if (context.mounted) Navigator.pop(context, true);
      } else {
        final body = await res.stream.bytesToString();
        try {
          final err = jsonDecode(body);
          _showSnack(err is Map && err['message'] != null
              ? "⚠️ ${err['message']}" : "Lỗi ${res.statusCode}: $body");
        } catch (_) { _showSnack("Lỗi ${res.statusCode}"); }
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
      filled: true, fillColor: Colors.white,
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
        title: const Text("Chỉnh sửa món ăn",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: mainColor, centerTitle: true, elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 12),
              Icon(Icons.fastfood_rounded, size: 90, color: Colors.orange.shade300),
              const SizedBox(height: 18),

              // ====== FORM ======
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputStyle("Tên món ăn", Icons.restaurant),
                validator: (v) => v == null || v.trim().isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 14),

              InputDecorator(
                decoration: _inputStyle("Loại món ăn", Icons.category),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    items: _categories.map((cat) =>
                        DropdownMenuItem<int>(value: cat['id'], child: Text(cat['name']))).toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _detailCtrl, maxLines: 3,
                decoration: _inputStyle("Mô tả chi tiết", Icons.description_outlined),
              ),
              const SizedBox(height: 22),

              // ====== ẢNH HIỆN TẠI ======
              if (_oldImages.isNotEmpty) ...[
                const Text("Ảnh hiện tại:", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _oldImages.map((url) {
                    final isMain = url == _mainImageUrl;
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        GestureDetector(
                          onTap: () => _previewImage(url),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isMain ? Colors.orangeAccent : Colors.grey.shade300,
                                width: isMain ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                Config_URL.baseUrl + url, width: 100, height: 100, fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () => _removeOldImage(url),
                            child: const CircleAvatar(
                              radius: 10, backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2, left: 2,
                          child: GestureDetector(
                            onTap: () => _setAsMain(url),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                              decoration: BoxDecoration(
                                color: isMain ? Colors.orange : Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(isMain ? "Ảnh chính" : "Ảnh phụ",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
              ],

              // ====== ẢNH MỚI ======
              const Text("Thêm ảnh mới:", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  ..._newImages.map((img) {
                    final isMain = _mainImageUrl == img.path;
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: isMain ? Colors.orange : Colors.transparent, width: 3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(File(img.path), width: 90, height: 90, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2, right: 2,
                          child: GestureDetector(
                            onTap: () => _removeNewImage(img),
                            child: const CircleAvatar(
                              radius: 10, backgroundColor: Colors.black54,
                              child: Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                        if (isMain)
                          Positioned(
                            bottom: 2, left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                              child: const Text("Ảnh chính",
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orangeAccent, width: 1.2),
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.orange, size: 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ====== NÚT LƯU ======
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(_isSaving ? "Đang lưu..." : "Lưu thay đổi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
