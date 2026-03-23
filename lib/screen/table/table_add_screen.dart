import 'package:flutter/material.dart';
import '../../services/table_service.dart';

class TableAddScreen extends StatefulWidget {
  const TableAddScreen({super.key});

  @override
  State<TableAddScreen> createState() => _TableAddScreenState();
}

class _TableAddScreenState extends State<TableAddScreen> {
  final _nameCtrl = TextEditingController();
  final _seatCtrl = TextEditingController();
  final _tableService = TableService();
  bool _isSaving = false;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final seat = int.tryParse(_seatCtrl.text);

    if (name.isEmpty || seat == null || seat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên bàn và số ghế hợp lệ")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _tableService.createTable(name, seat);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFFFFA500);
    const backgroundColor = Color(0xFFFFF8F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Thêm bàn mới",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Thông tin bàn",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Ô nhập tên bàn
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: "Tên bàn",
                  prefixIcon: const Icon(Icons.table_bar_rounded, color: mainColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: mainColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.03),
                ),
              ),
              const SizedBox(height: 18),

              // Ô nhập số ghế
              TextField(
                controller: _seatCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Số ghế",
                  prefixIcon: const Icon(Icons.chair_alt_rounded, color: mainColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: mainColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.03),
                ),
              ),

              const SizedBox(height: 30),

              // Nút lưu
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                  label: Text(
                    _isSaving ? "Đang lưu..." : "Lưu bàn",
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
