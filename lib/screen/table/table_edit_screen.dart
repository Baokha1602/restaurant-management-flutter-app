import 'package:flutter/material.dart';
import '../../model/table.dart';
import '../../services/table_service.dart';

class TableEditScreen extends StatefulWidget {
  final TableModel table;
  const TableEditScreen({super.key, required this.table});

  @override
  State<TableEditScreen> createState() => _TableEditScreenState();
}

class _TableEditScreenState extends State<TableEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _seatCtrl;
  final List<String> _statusOptions = ["Trống", "Đang sử dụng"];
  late String _status;
  final _tableService = TableService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.table.tableName);
    _seatCtrl = TextEditingController(text: widget.table.numberOfSeats.toString());
    _status = widget.table.tableStatus;
  }

  Future<void> _submit() async {
    final newName = _nameCtrl.text.trim();
    final newSeats = int.tryParse(_seatCtrl.text);
    if (newName.isEmpty || newSeats == null || newSeats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tên bàn hoặc số ghế không hợp lệ")),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = widget.table.copyWith(
        tableName: newName,
        numberOfSeats: newSeats,
        tableStatus: _status,
      );
      await _tableService.updateTable(updated);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      filled: true,
      fillColor: Colors.orange.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFFFFA500);
    const backgroundColor = Color(0xFFFFF8F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Chỉnh sửa bàn",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.table_bar_rounded,
                    size: 80, color: Colors.orangeAccent),
                const SizedBox(height: 20),

                // Tên bàn
                TextField(
                  controller: _nameCtrl,
                  decoration: _inputStyle("Tên bàn", Icons.edit_note_rounded),
                ),
                const SizedBox(height: 16),

                // Số ghế
                TextField(
                  controller: _seatCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                  _inputStyle("Số ghế", Icons.chair_alt_rounded),
                ),
                const SizedBox(height: 16),

                // Trạng thái
                InputDecorator(
                  decoration: _inputStyle("Trạng thái", Icons.info_outline),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _status,
                      isExpanded: true,
                      items: _statusOptions
                          .map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Icon(
                              s == "Trống"
                                  ? Icons.check_circle_outline
                                  : Icons.circle,
                              color: s == "Trống"
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(s),
                          ],
                        ),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
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
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      _isSaving ? "Đang lưu..." : "Lưu thay đổi",
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      foregroundColor: Colors.white,
                      elevation: 5,
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
      ),
    );
  }
}
