import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';

class DiscountAddScreen extends StatefulWidget {
  const DiscountAddScreen({super.key});

  @override
  State<DiscountAddScreen> createState() => _DiscountAddScreenState();
}

class _DiscountAddScreenState extends State<DiscountAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _requiredPointsCtrl = TextEditingController();
  final _dateStartCtrl = TextEditingController();
  final _dateEndCtrl = TextEditingController();
  String _selectedCategory = "Phần trăm";
  bool _isSaving = false;

  late final String apiUrl;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/DiscountApi";
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _requiredPointsCtrl.dispose();
    _dateStartCtrl.dispose();
    _dateEndCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final token = await _getBearerToken();
      if (token == null) {
        _showSnack("Token không tồn tại hoặc đã hết hạn!");
        return;
      }

      final model = {
        "discountId": "",
        "discountName": _nameCtrl.text.trim(),
        "discountCategory": _selectedCategory,
        "discountPrice": double.tryParse(_priceCtrl.text.trim()) ?? 0,
        "requiredPoints": int.tryParse(_requiredPointsCtrl.text.trim()) ?? 0,
        "dateStart": _dateStartCtrl.text.trim(),
        "dateEnd": _dateEndCtrl.text.trim(),
        "discountStatus": true
      };

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(model),
      );

      if (res.statusCode == 200) {
        _showSnack("✅ Thêm mã giảm giá thành công!");
        Navigator.pop(context, true);
      } else {
        _showSnack("❌ Thêm thất bại (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi: $e");
    } finally {
      setState(() => _isSaving = false);
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80), Color(0xFFFFB74D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 🔶 Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Thêm mã giảm giá",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 30),

                // 🧾 Card form
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Icon(Icons.discount_rounded,
                            size: 80, color: Colors.orange.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          "Tạo mã giảm giá mới",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 🔹 Các ô nhập liệu
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _inputStyle(
                              "Tên mã giảm giá", Icons.card_giftcard),
                          validator: (v) => v!.isEmpty
                              ? "Vui lòng nhập tên mã giảm giá"
                              : null,
                        ),
                        const SizedBox(height: 18),

                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration:
                          _inputStyle("Loại mã", Icons.category_outlined),
                          items: const [
                            DropdownMenuItem(
                                value: "Phần trăm", child: Text("Phần trăm")),
                            DropdownMenuItem(value: "Tiền", child: Text("Tiền")),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                          _inputStyle("Giá trị giảm", Icons.attach_money),
                          validator: (v) => v!.isEmpty
                              ? "Vui lòng nhập giá trị giảm"
                              : null,
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _requiredPointsCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                          _inputStyle("Điểm cần đổi", Icons.star_rate),
                          validator: (v) => v!.isEmpty
                              ? "Vui lòng nhập điểm cần đổi"
                              : null,
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _dateStartCtrl,
                          readOnly: true,
                          decoration: _inputStyle(
                            "Ngày bắt đầu",
                            Icons.date_range,
                            suffix: IconButton(
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.orange),
                              onPressed: () => _pickDate(_dateStartCtrl),
                            ),
                          ),
                          validator: (v) =>
                          v!.isEmpty ? "Chọn ngày bắt đầu" : null,
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _dateEndCtrl,
                          readOnly: true,
                          decoration: _inputStyle(
                            "Ngày kết thúc",
                            Icons.event,
                            suffix: IconButton(
                              icon: const Icon(Icons.calendar_month,
                                  color: Colors.orange),
                              onPressed: () => _pickDate(_dateEndCtrl),
                            ),
                          ),
                          validator: (v) =>
                          v!.isEmpty ? "Chọn ngày kết thúc" : null,
                        ),
                        const SizedBox(height: 30),

                        // 🔘 Nút lưu
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          icon: _isSaving
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSaving ? "Đang lưu..." : "Lưu mã giảm giá",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
