import 'package:flutter/material.dart';
import '../../model/table.dart';
import '../../services/table_service.dart';
import '../../config/config_url.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  late Future<List<TableModel>> _tablesFuture;
  final TableService _tableService = TableService();
  final List<String> _statusOptions = ["Trống", "Đang sử dụng"];
  final Color primaryColor = const Color(0xFFF57C00); // Vibrant Orange from Login Screen

  @override
  void initState() {
    super.initState();
    _refreshTableList();
  }

  void _refreshTableList() {
    setState(() {
      _tablesFuture = _tableService.getTables();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showTableDialog({TableModel? table}) {
    final isUpdating = table != null;
    final TextEditingController nameController = TextEditingController(text: table?.tableName ?? '');
    final TextEditingController seatsController = TextEditingController(text: table?.numberOfSeats.toString() ?? '');
    String currentStatus = table?.tableStatus ?? 'Trống';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(isUpdating ? 'Cập nhật bàn' : 'Tạo bàn mới', style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên bàn',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: seatsController,
                    decoration: InputDecoration(
                      labelText: 'Số ghế',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (isUpdating) ...[
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: currentStatus,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          currentStatus = newValue!;
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final String name = nameController.text;
              final int? seats = int.tryParse(seatsController.text);

              if (name.isNotEmpty && seats != null && seats > 0) {
                try {
                  if (isUpdating) {
                    final updatedTable = table.copyWith(
                      tableName: name,
                      numberOfSeats: seats,
                      tableStatus: currentStatus,
                    );
                    await _tableService.updateTable(updatedTable);
                  } else {
                    await _tableService.createTable(name, seats);
                  }
                  Navigator.pop(context);
                  _refreshTableList();
                } catch (e) {
                  Navigator.pop(context);
                  _showErrorDialog("Đã xảy ra lỗi: ${e.toString()}");
                }
              } else {
                _showErrorDialog("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
              }
            },
            child: Text(isUpdating ? 'Cập nhật' : 'Tạo', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(TableModel table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa bàn ${table.tableName}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _tableService.deleteTable(table.tableId);
                Navigator.pop(context);
                _refreshTableList();
              } catch (e) {
                Navigator.pop(context);
                _showErrorDialog("Lỗi khi xóa bàn: ${e.toString()}");
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showQrCodeDialog(String qrCodePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Quét mã để đặt bàn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Image.network(
              Config_URL.baseUrl + qrCodePath,
              errorBuilder: (context, error, stackTrace) => const Center(child: Text("Không thể tải mã QR")),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quản lý bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tạo bàn mới',
            onPressed: () => _showTableDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
            onPressed: _refreshTableList,
          ),
        ],
      ),
      body: FutureBuilder<List<TableModel>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có bàn nào được tạo.'));
          }

          final tables = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Card(
                elevation: 2.0,
                shadowColor: Colors.black26,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                 clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowHeight: 60,
                    headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
                    columns: const [
                      DataColumn(label: Text('Tên bàn', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Số ghế', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Chủ bàn', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Mã QR', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: tables.map((table) {
                      final statusColor = table.tableStatus == 'Đang sử dụng' ? Colors.redAccent : Colors.green;
                      return DataRow(
                        cells: [
                          DataCell(Text(table.tableName, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(table.numberOfSeats.toString())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(table.tableStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          // TODO: Fetch customer name from ID
                          DataCell(Text(table.ownerTable ?? '--')),
                          DataCell(
                            (table.qrCodePath != null && table.qrCodePath!.isNotEmpty)
                                ? IconButton(
                                    icon: Icon(Icons.qr_code_scanner_rounded, color: Colors.grey[700]),
                                    tooltip: 'Xem mã QR',
                                    onPressed: () => _showQrCodeDialog(table.qrCodePath!),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 8)
                                    ),
                                    onPressed: () async {
                                      try {
                                        await _tableService.createQr(table.tableId);
                                        _refreshTableList();
                                      } catch (e) {
                                        _showErrorDialog("Lỗi khi tạo mã QR: ${e.toString()}");
                                      }
                                    },
                                    child: const Text('Tạo QR', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blueGrey[600]),
                                  tooltip: 'Cập nhật',
                                  onPressed: () => _showTableDialog(table: table),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red[400]),
                                  tooltip: 'Xóa',
                                  onPressed: () => _showDeleteConfirmDialog(table),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
