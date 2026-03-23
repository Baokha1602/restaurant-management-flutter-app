import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/config_url.dart';
import '../../model/table.dart';
import '../../services/table_service.dart';
import 'table_add_screen.dart';
import 'table_edit_screen.dart';

class TableListScreen extends StatefulWidget {
  const TableListScreen({super.key});

  @override
  State<TableListScreen> createState() => _TableListScreenState();
}

class _TableListScreenState extends State<TableListScreen> {
  late Future<List<TableModel>> _tablesFuture;
  final TableService _tableService = TableService();

  @override
  void initState() {
    super.initState();
    _refreshTableList();
  }

  Future<void> _refreshTableList() async {
    setState(() {
      _tablesFuture = _tableService.getTables();
    });
  }

  void _showSnack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: success ? Colors.green : Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(String qrPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("📱 Mã QR của bàn",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  Config_URL.baseUrl + qrPath,
                  width: 240,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.error,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text("Đóng"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFFFF9800);
    const backgroundColor = Color(0xFFFFF8F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Quản lý bàn",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            tooltip: "Thêm bàn mới",
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TableAddScreen()),
              );
              if (added == true) _refreshTableList();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<TableModel>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: mainColor));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Lỗi: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final tables = snapshot.data ?? [];
          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_restaurant_rounded,
                      size: 120, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "Chưa có bàn nào",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: mainColor,
            onRefresh: _refreshTableList,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              itemCount: tables.length,
              itemBuilder: (context, i) {
                final t = tables[i];
                final hasQr = t.qrCodePath?.isNotEmpty == true;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: hasQr ? () => _showQrDialog(t.qrCodePath!) : null,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.orange.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: hasQr
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                Config_URL.baseUrl + t.qrCodePath!,
                                fit: BoxFit.cover,
                              ),
                            )
                                : const Icon(Icons.qr_code_2,
                                color: Colors.orange, size: 40),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tên bàn: ${t.tableName}",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              const SizedBox(height: 6),
                              Text("Số ghế: ${t.numberOfSeats}",
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black54)),
                              const SizedBox(height: 6),
                              // ✅ ĐÃ FIX PHẦN TRÀN CHỮ
                              Row(
                                children: [
                                  const Text(
                                    "Trạng thái: ",
                                    style: TextStyle(fontSize: 15, color: Colors.black54),
                                  ),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: t.tableStatus == "Trống"
                                            ? Colors.green.withOpacity(0.15)
                                            : Colors.redAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        t.tableStatus,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: t.tableStatus == "Trống"
                                              ? Colors.green.shade700
                                              : Colors.redAccent.shade200,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 26),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TableEditScreen(table: t)),
                              );
                              if (updated == true) _refreshTableList();
                            } else if (value == 'delete') {
                              try {
                                final result = await _tableService.deleteTable(t.tableId);
                                if (result != null) {
                                  final data = jsonDecode(result);
                                  final msg = data['message'] ?? "Xóa bàn thành công";
                                  final success = data['isSuccess'] ?? true;

                                  if (!success && msg.contains("sử dụng")) {
                                    _showSnack(msg, success: false);
                                  } else if (!success) {
                                    _showErrorDialog(msg);
                                  } else {
                                    _showSnack(msg);
                                    _refreshTableList();
                                  }
                                }
                              } catch (e) {
                                _showErrorDialog("Không thể xóa bàn: $e");
                              }
                            } else if (value == 'qr' && !hasQr) {
                              try {
                                await _tableService.createQr(t.tableId);
                                _showSnack("✅ Đã tạo mã QR thành công");
                                _refreshTableList();
                              } catch (e) {
                                _showErrorDialog("Lỗi khi tạo mã QR: $e");
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blueAccent, size: 22),
                                  SizedBox(width: 8),
                                  Text("Chỉnh sửa", style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.redAccent, size: 22),
                                  SizedBox(width: 8),
                                  Text("Xóa", style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                            if (!hasQr)
                              const PopupMenuItem(
                                value: 'qr',
                                child: Row(
                                  children: [
                                    Icon(Icons.qr_code, color: Colors.orange, size: 22),
                                    SizedBox(width: 8),
                                    Text("Tạo mã QR", style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
