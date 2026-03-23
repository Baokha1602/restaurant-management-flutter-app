import 'package:flutter/material.dart';
import '../../../models/customer_rank.dart';
class CustomerRankForm extends StatefulWidget {
  final CustomerRank? initialRank;
  final Function(CustomerRank) onSave;

  const CustomerRankForm({
    super.key,
    this.initialRank,
    required this.onSave,
  });

  @override
  State<CustomerRankForm> createState() => _CustomerRankFormState();
}

class _CustomerRankFormState extends State<CustomerRankForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rankNameController;
  late TextEditingController _rankPointController;
  late TextEditingController _rankDiscountController;

  final Color primaryOrange = const Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _rankNameController =
        TextEditingController(text: widget.initialRank?.rankName ?? '');
    _rankPointController = TextEditingController(
        text: widget.initialRank?.rankPoint?.toString() ?? '');
    _rankDiscountController = TextEditingController(
        text: widget.initialRank?.rankDiscount?.toString() ?? '');
  }

  @override
  void dispose() {
    _rankNameController.dispose();
    _rankPointController.dispose();
    _rankDiscountController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newRank = CustomerRank(
        rankId: widget.initialRank?.rankId,
        rankName: _rankNameController.text.trim(),
        rankPoint: int.parse(_rankPointController.text),
        rankDiscount: int.tryParse(_rankDiscountController.text),
      );
      widget.onSave(newRank);
      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: primaryOrange),
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryOrange, width: 1.6),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.orange.shade50.withOpacity(0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRank != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_circle_rounded,
                    color: primaryOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Cập Nhật Hạng Khách Hàng' : 'Thêm Hạng Khách Hàng',
                    style: TextStyle(
                      color: primaryOrange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _rankNameController,
                    decoration: _inputDecoration(
                      label: 'Tên Hạng',
                      icon: Icons.workspace_premium_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên hạng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _rankPointController,
                    decoration: _inputDecoration(
                      label: 'Điểm Hạng',
                      icon: Icons.star_rate_rounded,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập điểm hạng';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Điểm hạng phải là số nguyên không âm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _rankDiscountController,
                    decoration: _inputDecoration(
                      label: 'Chiết Khấu (%)',
                      icon: Icons.percent_rounded,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final discount = int.tryParse(value);
                        if (discount == null ||
                            discount < 0 ||
                            discount > 100) {
                          return 'Chiết khấu phải từ 0 đến 100';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveForm,
                      icon: Icon(
                        isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        isEditing ? 'Cập Nhật Hạng' : 'Thêm Hạng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
