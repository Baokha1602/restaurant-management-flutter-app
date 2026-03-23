import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:restaurantmanager/config/config_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeAddScreen extends StatefulWidget {
  const EmployeeAddScreen({super.key});

  @override
  State<EmployeeAddScreen> createState() => _EmployeeAddScreenState();
}

class _EmployeeAddScreenState extends State<EmployeeAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  int _gender = 1;
  File? _imageFile;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('jwt_token');
    if (t == null) return null;
    return t.startsWith('Bearer ') ? t : 'Bearer $t';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await _getToken();
    if (token == null) return;

    final uri = Uri.parse("${Config_URL.baseApiUrl}/EmployeeApi");

    try {
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = token;

      request.fields['Name'] = _nameCtrl.text;
      request.fields['Email'] = _emailCtrl.text;
      request.fields['PhoneNumber'] = _phoneCtrl.text;
      request.fields['DateOfBirth'] = _dobCtrl.text;
      request.fields['Gender'] = _gender.toString();
      request.fields['Password'] = _passwordCtrl.text;
      request.fields['ConfirmPassword'] = _confirmPasswordCtrl.text;

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          _imageFile!.path,
        ));
      }

      final response = await request.send();
      final res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Thêm nhân viên thành công!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Thêm thất bại: ${res.body}")),
        );
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
        title: const Text("Thêm nhân viên", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Avatar + chọn ảnh
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.orange.shade100,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : const AssetImage('assets/images/default_user.png')
                      as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Các ô nhập liệu
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration("Họ và tên", Icons.person_outline),
                validator: (v) => v!.isEmpty ? "Nhập tên" : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailCtrl,
                decoration: _inputDecoration("Email", Icons.email_outlined),
                validator: (v) => v!.isEmpty ? "Nhập email" : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneCtrl,
                decoration: _inputDecoration("Số điện thoại", Icons.phone_outlined),
              ),
              const SizedBox(height: 14),

              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dobCtrl,
                    decoration: _inputDecoration("Ngày sinh (chọn)", Icons.calendar_today_outlined),
                    validator: (v) => v!.isEmpty ? "Chọn ngày sinh" : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Nam")),
                  DropdownMenuItem(value: 0, child: Text("Nữ")),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 1),
                decoration: _inputDecoration("Giới tính", Icons.wc_outlined),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: _inputDecoration("Mật khẩu", Icons.lock_outline),
                validator: (v) => v!.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: _inputDecoration("Xác nhận mật khẩu", Icons.lock_reset_outlined),
                validator: (v) => v != _passwordCtrl.text ? "Mật khẩu không trùng khớp" : null,
              ),
              const SizedBox(height: 28),

              // Nút lưu
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Lưu nhân viên"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
