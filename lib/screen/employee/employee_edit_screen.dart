import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:restaurantmanager/config/config_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeEditScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EmployeeEditScreen({super.key, required this.employee});

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  File? _imageFile;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;
  late int _gender;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.employee['name'] ?? '');
    _emailCtrl = TextEditingController(text: widget.employee['email'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.employee['phoneNumber'] ?? '');
    _dobCtrl = TextEditingController(text: widget.employee['dateOfBirth'] ?? '');
    _gender = widget.employee['gender'] ?? 1;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return null;
    return token.startsWith('Bearer ') ? token : 'Bearer $token';
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

    final uri = Uri.parse("${Config_URL.baseApiUrl}/EmployeeApi/${widget.employee['id']}");
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = token;

    request.fields['Id'] = widget.employee['id'].toString();
    request.fields['Name'] = _nameCtrl.text;
    request.fields['Email'] = _emailCtrl.text;
    request.fields['PhoneNumber'] = _phoneCtrl.text;
    request.fields['DateOfBirth'] = _dobCtrl.text;
    request.fields['Gender'] = _gender.toString();

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('imageFile', _imageFile!.path));
    }

    try {
      final response = await request.send();
      final res = await http.Response.fromStream(response);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cập nhật thành công!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Cập nhật thất bại: ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi cập nhật: $e")),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
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
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  // 🔹 Chọn ngày sinh thân thiện
  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();
    DateTime? initialDate;
    try {
      if (_dobCtrl.text.isNotEmpty) {
        initialDate = DateTime.parse(_dobCtrl.text);
      }
    } catch (_) {}

    final DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1960),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: "Chọn ngày sinh",
      cancelText: "Hủy",
      confirmText: "Chọn",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
      setState(() => _dobCtrl.text = formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.employee['urlImage'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text("Chỉnh sửa nhân viên",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
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
              const SizedBox(height: 10),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.orange.shade100,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (currentImage != null &&
                          currentImage.toString().isNotEmpty)
                          ? NetworkImage("${Config_URL.baseUrl}$currentImage")
                      as ImageProvider
                          : const AssetImage('assets/images/default_user.png'),
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
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Họ và tên
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration("Họ và tên", Icons.person_outline),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập họ tên" : null,
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: _inputDecoration("Email", Icons.email_outlined),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập email" : null,
              ),
              const SizedBox(height: 14),

              // Số điện thoại
              TextFormField(
                controller: _phoneCtrl,
                decoration:
                _inputDecoration("Số điện thoại", Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Ngày sinh (DatePicker)
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                decoration: _inputDecoration("Ngày sinh", Icons.calendar_today_outlined)
                    .copyWith(
                  suffixIcon: const Icon(Icons.date_range, color: Colors.orange),
                ),
                onTap: _pickDateOfBirth,
                validator: (v) =>
                v == null || v.isEmpty ? "Vui lòng chọn ngày sinh" : null,
              ),
              const SizedBox(height: 14),

              // Giới tính
              DropdownButtonFormField<int>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Nam")),
                  DropdownMenuItem(value: 0, child: Text("Nữ")),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 1),
                decoration: _inputDecoration("Giới tính", Icons.wc_outlined),
              ),
              const SizedBox(height: 28),

              // Nút lưu thay đổi
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Lưu thay đổi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
