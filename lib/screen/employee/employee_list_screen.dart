import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';
import 'package:restaurantmanager/models/employee_model.dart';
import 'employee_add_screen.dart';
import 'employee_edit_screen.dart';
import 'package:intl/intl.dart'; // ✅ để format ngày

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Employee> _employees = [];
  bool _isLoading = false;

  late final String apiUrl;
  int _page = 1;
  final int _pageSize = 8;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/EmployeeApi";
    _fetchEmployees();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchCtrl.text.trim();
      _fetchEmployees(search: query);
    });
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _fetchEmployees({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final uri = Uri.parse(
        "$apiUrl${search != null && search.isNotEmpty ? '?search=$search' : ''}",
      );

      final res = await http.get(uri, headers: {'Authorization': token});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() => _employees = data.map((e) => Employee.fromJson(e)).toList());
        }
      } else {
        _showSnack("Không thể tải dữ liệu (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi tải dữ liệu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEmployee(String id, String name) async {
    try {
      final token = await _getBearerToken();
      if (token == null) return;
      final uri = Uri.parse("$apiUrl/$id");

      final res = await http.delete(uri, headers: {'Authorization': token});
      if (res.statusCode == 200) {
        setState(() => _employees.removeWhere((e) => e.id == id));
        _showSnack("Đã xóa $name");
      } else {
        _showSnack("Xóa thất bại (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi xóa: $e");
    }
  }

  Future<bool> _askConfirmDelete(String id, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa nhân viên '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ✅ Làm đẹp phần hiển thị chi tiết nhân viên
  void _showDetail(Employee emp) {
    final urlImage = emp.urlImage;
    final date = emp.dateOfBirth;
    String formattedDate = 'Không có';
    if (date != null && date.isNotEmpty) {
      try {
        formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFFFBF5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ảnh đại diện
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orange.shade100,
                backgroundImage: (urlImage != null && urlImage.isNotEmpty)
                    ? NetworkImage("${Config_URL.baseUrl}$urlImage")
                    : const AssetImage('assets/images/default_user.png')
                as ImageProvider,
              ),
              const SizedBox(height: 12),

              // Tên
              Text(
                emp.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: emp.gender == 1
                      ? Colors.blueAccent.withOpacity(0.15)
                      : Colors.pinkAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  emp.gender == 1 ? "Nam" : "Nữ",
                  style: TextStyle(
                    color: emp.gender == 1 ? Colors.blueAccent : Colors.pink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Thông tin chi tiết dạng card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 1,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.email_outlined, emp.email ?? '-'),
                      _buildDetailRow(Icons.phone, emp.phoneNumber ?? '-'),
                      _buildDetailRow(Icons.cake, formattedDate),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("Đóng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  List<Employee> get _pagedEmployees {
    final start = (_page - 1) * _pageSize;
    final end = (_page * _pageSize).clamp(0, _employees.length);
    return _employees.sublist(start, end);
  }

  int get _totalPages => (_employees.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý nhân viên",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.orange,
          icon: const Icon(Icons.add),
          label: const Text("Thêm nhân viên"),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeAddScreen()),
            );
            if (added == true) _fetchEmployees();
          },
        ),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm nhân viên...",
                  hintStyle:
                  TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Danh sách nhân viên
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(color: Colors.orange))
                : _employees.isEmpty
                ? const Center(child: Text("Không có dữ liệu nhân viên"))
                : ListView.builder(
              itemCount: _pagedEmployees.length,
              itemBuilder: (_, i) {
                final e = _pagedEmployees[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Colors.orange.withOpacity(0.2),
                  onLongPress: () async {
                    await Future.delayed(
                        const Duration(milliseconds: 100));
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EmployeeEditScreen(employee: e.toJson()),
                      ),
                    );
                    if (updated == true) _fetchEmployees();
                  },
                  child: Dismissible(
                    key: Key(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete,
                          color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      final ok =
                      await _askConfirmDelete(e.id, e.name);
                      if (ok) await _deleteEmployee(e.id, e.name);
                      return ok;
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.orange.shade100,
                          backgroundImage: (e.urlImage != null &&
                              e.urlImage!.isNotEmpty)
                              ? NetworkImage(
                              "${Config_URL.baseUrl}${e.urlImage}")
                              : const AssetImage(
                              'assets/images/default_user.png')
                          as ImageProvider,
                        ),
                        title: Text(e.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${e.email ?? '-'}\n${e.phoneNumber ?? '-'}",
                          style:
                          const TextStyle(color: Colors.black87),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Colors.orange),
                          onPressed: () => _showDetail(e),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Phân trang
          if (_employees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Wrap(
                spacing: 6,
                children: List.generate(_totalPages, (index) {
                  final pageNum = index + 1;
                  final active = pageNum == _page;
                  return ElevatedButton(
                    onPressed: () => setState(() => _page = pageNum),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      active ? Colors.orange : Colors.grey.shade300,
                      foregroundColor:
                      active ? Colors.white : Colors.black87,
                    ),
                    child: Text(pageNum.toString()),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
