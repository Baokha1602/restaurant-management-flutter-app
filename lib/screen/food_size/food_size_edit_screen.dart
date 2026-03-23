import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:restaurantmanager/config/config_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodSizeEditScreen extends StatefulWidget {
  final Map<String, dynamic> foodSize;
  const FoodSizeEditScreen({super.key, required this.foodSize});

  @override
  State<FoodSizeEditScreen> createState() => _FoodSizeEditScreenState();
}

class _FoodSizeEditScreenState extends State<FoodSizeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController();
  final _menuSearchCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _menuSuggestions = [];

  int? _selectedMenuId;
  String? _selectedMenuName;

  late final String apiUrl;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/FoodSizeApi";

    _foodNameCtrl.text = widget.foodSize['foodName'] ?? '';
    _priceCtrl.text = widget.foodSize['price'].toString();
    _sortOrderCtrl.text = widget.foodSize['sortOrder'].toString();
    _selectedMenuId = widget.foodSize['menuId'];
    _selectedMenuName = widget.foodSize['menuName'] ?? '';
    _menuSearchCtrl.text = _selectedMenuName ?? '';

    _menuSearchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _menuSearchCtrl.removeListener(_onSearchChanged);
    _menuSearchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  void _onSearchChanged() {
    final query = _menuSearchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _menuSuggestions = []);
      return;
    }
    _fetchMenuSuggestions(query);
  }

  Future<void> _fetchMenuSuggestions(String query) async {
    setState(() => _isSearching = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final uri = Uri.parse("${Config_URL.baseApiUrl}/MenuApi?search=$query");
      final res = await http.get(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _menuSuggestions = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (_) {} finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _updateSize() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMenuId == null) {
      _showSnack("Vui lòng chọn món ăn!");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final model = {
        "foodSizeId": widget.foodSize['foodSizeId'],
        "foodName": _foodNameCtrl.text.trim(),
        "menuId": _selectedMenuId,
        "price": double.parse(_priceCtrl.text.trim()),
        "sortOrder": int.tryParse(_sortOrderCtrl.text.trim()) ?? 0,
      };

      final res = await http.put(
        Uri.parse("$apiUrl/${widget.foodSize['foodSizeId']}"),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(model),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["isSuccess"] == true) {
        _showSnack(data["message"] ?? "✅ Cập nhật thành công!");
        Navigator.pop(context, true);
      } else {
        _showSnack(data["message"] ?? "❌ Cập nhật thất bại");
      }
    } catch (e) {
      _showSnack("Lỗi cập nhật: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _inputStyle(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2)),
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
          "Chỉnh sửa kích cỡ món ăn",
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
              Icon(Icons.edit_square, size: 90, color: Colors.orange.shade300),
              const SizedBox(height: 16),
              Text(
                "Cập nhật kích cỡ món ăn",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 35),

              // 🔍 Ô tìm kiếm món ăn realtime
              Stack(
                children: [
                  TextFormField(
                    controller: _menuSearchCtrl,
                    decoration: _inputStyle(
                      "Tìm và chọn món ăn",
                      Icons.restaurant_menu,
                      suffix: _isSearching
                          ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.orange),
                        ),
                      )
                          : const Icon(Icons.search, color: Colors.orange),
                    ),
                  ),
                  if (_menuSuggestions.isNotEmpty)
                    Positioned(
                      top: 65,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: _menuSuggestions.map((menu) {
                            return ListTile(
                              leading: const Icon(Icons.local_dining,
                                  color: Colors.orange),
                              title: Text(menu['menuName'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(menu['menuCategoryName'] ?? '',
                                  style:
                                  const TextStyle(color: Colors.black54)),
                              onTap: () {
                                setState(() {
                                  _selectedMenuId = menu['menuId'];
                                  _selectedMenuName = menu['menuName'];
                                  _menuSearchCtrl.text = menu['menuName'];
                                  _menuSuggestions.clear();
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔹 Tên kích cỡ
              TextFormField(
                controller: _foodNameCtrl,
                decoration: _inputStyle("Tên kích cỡ (S, M, L...)", Icons.rice_bowl),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Vui lòng nhập tên kích cỡ" : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Giá
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputStyle("Giá bán", Icons.attach_money),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Vui lòng nhập giá bán" : null,
              ),
              const SizedBox(height: 20),

              // 🔹 Thứ tự
              TextFormField(
                controller: _sortOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputStyle("Thứ tự hiển thị", Icons.sort),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Vui lòng nhập thứ tự" : null,
              ),
              const SizedBox(height: 30),

              // 🔹 Nút lưu
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _updateSize,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSubmitting ? "Đang lưu..." : "Lưu thay đổi",
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
