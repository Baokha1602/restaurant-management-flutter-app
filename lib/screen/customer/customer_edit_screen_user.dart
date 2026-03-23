import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

class CustomerEditScreen extends StatefulWidget {
  final CustomerDTO customer;
  const CustomerEditScreen({super.key, required this.customer, required List ranks});

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final CustomerService _customerService = CustomerService();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;
  late int _gender;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _emailCtrl = TextEditingController(text: widget.customer.email);
    _phoneCtrl = TextEditingController(text: widget.customer.phoneNumber);
    _dobCtrl = TextEditingController(
      text: widget.customer.dateOfBirth != null &&
          widget.customer.dateOfBirth!.isNotEmpty
          ? widget.customer.dateOfBirth!.split('T')[0]
          : '',
    );
    _gender = widget.customer.gender;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.tryParse(_dobCtrl.text) ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    widget.customer
      ..name = _nameCtrl.text
      ..email = _emailCtrl.text
      ..phoneNumber = _phoneCtrl.text
      ..gender = _gender
      ..dateOfBirth = _dobCtrl.text;

    try {
      await _customerService.updateCustomer(widget.customer, _selectedImage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Cập nhật khách hàng thành công!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Lỗi: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.orange, width: 2),
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
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                    ),
                    const Text(
                      "Sửa khách hàng",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 10),

                // Card chứa form
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
                        // Ảnh đại diện
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.orange.shade100,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : NetworkImage(widget.customer.fullImageUrl)
                              as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 22, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Họ tên
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _inputStyle("Họ và tên", Icons.person),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Không được để trống" : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          readOnly: true,
                          decoration: _inputStyle("Email", Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Số điện thoại
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration:
                          _inputStyle("Số điện thoại", Icons.phone_iphone),
                          validator: (v) =>
                          v == null || v.isEmpty ? "Không được để trống" : null,
                        ),
                        const SizedBox(height: 16),

                        // Ngày sinh
                        TextFormField(
                          controller: _dobCtrl,
                          readOnly: true,
                          decoration: _inputStyle("Ngày sinh", Icons.cake).copyWith(
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month,
                                  color: Colors.orange),
                              onPressed: _pickDate,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Giới tính
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<int>(
                                title: const Text("Nam"),
                                value: 1,
                                groupValue: _gender,
                                activeColor: mainColor,
                                onChanged: (v) => setState(() => _gender = v ?? 1),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<int>(
                                title: const Text("Nữ"),
                                value: 0,
                                groupValue: _gender,
                                activeColor: mainColor,
                                onChanged: (v) => setState(() => _gender = v ?? 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Nút lưu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveCustomer,
                            icon: _isSaving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              _isSaving ? "Đang lưu..." : "Lưu thay đổi",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
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
