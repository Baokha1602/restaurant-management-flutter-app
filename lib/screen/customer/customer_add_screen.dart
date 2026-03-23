import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/customer_rank.dart';
import '../../services/customer_service.dart';

class CustomerAddScreen extends StatefulWidget {
  final List<CustomerRank> ranks;
  const CustomerAddScreen({super.key, required this.ranks});

  @override
  State<CustomerAddScreen> createState() => _CustomerAddScreenState();
}

class _CustomerAddScreenState extends State<CustomerAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerService = CustomerService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _dob;
  int _gender = 0;
  int? _selectedRankId;
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _registerCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      _showSnack("Vui lòng chọn ngày sinh");
      return;
    }
    if (_selectedRankId == null) {
      _showSnack("Vui lòng chọn hạng khách hàng");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _customerService.register(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dob!.toIso8601String(),
        gender: _gender,
        rankId: _selectedRankId!,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        imageFile: _imageFile,
      );

      setState(() => _isLoading = false);
      if (response['success'] == true) {
        _showSnack("✅ Tạo tài khoản thành công!");
        Navigator.pop(context, true);
      } else {
        _showSnack(
            "❌ ${response['body']?['message'] ?? 'Tạo thất bại, vui lòng thử lại.'}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Lỗi: $e");
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
            child: Column(
              children: [
                // AppBar tùy chỉnh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    ),
                    const Text(
                      "Thêm khách hàng",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 10),

                // Card nội dung
                Container(
                  padding: const EdgeInsets.all(20),
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
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.orange.shade100,
                            backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                            child: _imageFile == null
                                ? const Icon(Icons.camera_alt,
                                color: Colors.orange, size: 36)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tên
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputStyle("Họ và tên", Icons.person),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Nhập họ tên" : null,
                        ),
                        const SizedBox(height: 16),

                        // Điện thoại
                        TextFormField(
                          controller: _phoneController,
                          decoration: _inputStyle("Số điện thoại", Icons.phone),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Nhập số điện thoại" : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputStyle("Email", Icons.email_outlined),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Nhập email" : null,
                        ),
                        const SizedBox(height: 16),

                        // Mật khẩu
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputStyle("Mật khẩu", Icons.lock_outline),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Nhập mật khẩu" : null,
                        ),
                        const SizedBox(height: 16),

                        // Xác nhận mật khẩu
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration:
                          _inputStyle("Xác nhận mật khẩu", Icons.lock_reset),
                          validator: (v) => v != _passwordController.text
                              ? "Mật khẩu không khớp"
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Ngày sinh
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _dob == null
                                ? 'Chọn ngày sinh'
                                : 'Ngày sinh: ${_dob!.day}/${_dob!.month}/${_dob!.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.orange),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _dob = picked);
                          },
                        ),
                        const Divider(thickness: 1),

                        // Giới tính
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<int>(
                                value: 0,
                                groupValue: _gender,
                                title: const Text("Nam"),
                                activeColor: mainColor,
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<int>(
                                value: 1,
                                groupValue: _gender,
                                title: const Text("Nữ"),
                                activeColor: mainColor,
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Hạng
                        DropdownButtonFormField<int>(
                          decoration:
                          _inputStyle("Hạng khách hàng", Icons.workspace_premium),
                          value: _selectedRankId,
                          items: widget.ranks
                              .map((r) => DropdownMenuItem(
                            value: r.rankId,
                            child: Text(r.rankName),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRankId = v),
                          validator: (v) =>
                          v == null ? "Chọn hạng khách hàng" : null,
                        ),
                        const SizedBox(height: 24),

                        // Nút lưu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _registerCustomer,
                            icon: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.person_add_alt_1,
                                color: Colors.white),
                            label: Text(
                              _isLoading
                                  ? "Đang xử lý..."
                                  : "Tạo khách hàng",
                              style:
                              const TextStyle(fontWeight: FontWeight.w600),
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
