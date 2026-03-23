import 'package:flutter/material.dart';

class EmployeeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? employee;
  final Function(Map<String, dynamic>) onSubmit;

  const EmployeeFormDialog({super.key, this.employee, required this.onSubmit});

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;
  int _gender = 1; // 1 = Nam, 0 = Nữ

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.employee?['name'] ?? '');
    _emailCtrl = TextEditingController(text: widget.employee?['email'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.employee?['phoneNumber'] ?? '');
    _dobCtrl = TextEditingController(text: widget.employee?['dateOfBirth'] ?? '');
    _gender = widget.employee?['gender'] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;

    return AlertDialog(
      title: Text(isEdit ? "Cập nhật nhân viên" : "Thêm nhân viên mới"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Họ và tên"),
                validator: (v) => v == null || v.isEmpty ? "Nhập tên" : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v == null || v.isEmpty ? "Nhập email" : null,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: "Số điện thoại"),
              ),
              TextFormField(
                controller: _dobCtrl,
                decoration: const InputDecoration(labelText: "Ngày sinh (yyyy-MM-dd)"),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Nam")),
                  DropdownMenuItem(value: 0, child: Text("Nữ")),
                ],
                onChanged: (v) => _gender = v ?? 1,
                decoration: const InputDecoration(labelText: "Giới tính"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit({
                'name': _nameCtrl.text,
                'email': _emailCtrl.text,
                'phoneNumber': _phoneCtrl.text,
                'dateOfBirth': _dobCtrl.text,
                'gender': _gender,
              });
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? "Cập nhật" : "Thêm"),
        ),
      ],
    );
  }
}
