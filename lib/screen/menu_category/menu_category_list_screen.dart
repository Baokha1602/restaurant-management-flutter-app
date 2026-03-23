import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:restaurantmanager/config/config_url.dart';
import 'package:restaurantmanager/models/menu_category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_category_add_screen.dart';
import 'menu_category_edit_screen.dart';

class MenuCategoryListScreen extends StatefulWidget {
  const MenuCategoryListScreen({super.key});

  @override
  State<MenuCategoryListScreen> createState() => _MenuCategoryListScreenState();
}

class _MenuCategoryListScreenState extends State<MenuCategoryListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<MenuCategory> _categories = [];
  List<MenuCategory> _filteredCategories = [];
  bool _isLoading = false;

  late final String apiUrl;
  int _page = 1;
  final int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/MenuCategoryApi";
    _fetchCategories();

    // Lắng nghe nhập liệu để lọc realtime
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((c) =>
        c.menuCategoryName.toLowerCase().contains(query) ||
            c.menuCategoryId.toString().contains(query))
            .toList();
      }
      _page = 1; // reset về trang đầu mỗi khi tìm
    });
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final uri = Uri.parse(apiUrl);
      final res = await http.get(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _categories = data.map((e) => MenuCategory.fromJson(e)).toList();
            _filteredCategories = _categories; // hiển thị ban đầu
          });
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

  Future<void> _deleteCategory(int id, String name) async {
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final uri = Uri.parse("$apiUrl/$id");
      final res = await http.delete(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        setState(() {
          _categories.removeWhere((e) => e.menuCategoryId == id);
          _filteredCategories.removeWhere((e) => e.menuCategoryId == id);
        });
        _showSnack("Đã xóa loại món '$name'");
      } else {
        _showSnack("Xóa thất bại (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi xóa: $e");
    }
  }

  Future<bool> _askConfirmDelete(int id, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa loại món '$name'?"),
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

  void _showDetail(MenuCategory category) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.fastfood, color: Colors.orange, size: 40),
              ),
              const SizedBox(height: 10),
              Text(
                category.menuCategoryName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text("ID: ${category.menuCategoryId}",
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("Đóng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MenuCategory> get _pagedCategories {
    final start = (_page - 1) * _pageSize;
    final end = (_page * _pageSize).clamp(0, _filteredCategories.length);
    return _filteredCategories.sublist(start, end);
  }

  int get _totalPages => (_filteredCategories.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý loại món ăn",
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
          label: const Text("Thêm loại món"),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MenuCategoryAddScreen()),
            );
            if (added == true) _fetchCategories();
          },
        ),
      ),
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm realtime
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
                  hintText: "Tìm kiếm loại món ăn...",
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // 📋 Danh sách realtime
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _filteredCategories.isEmpty
                ? const Center(child: Text("Không có dữ liệu loại món ăn"))
                : ListView.builder(
              itemCount: _pagedCategories.length,
              itemBuilder: (_, i) {
                final c = _pagedCategories[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Colors.orange.withOpacity(0.2),
                  onLongPress: () async {
                    await Future.delayed(const Duration(milliseconds: 100));
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuCategoryEditScreen(category: c.toJson()),
                      ),
                    );
                    if (updated == true) _fetchCategories();
                  },
                  child: Dismissible(
                    key: Key(c.menuCategoryId.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      final ok =
                      await _askConfirmDelete(c.menuCategoryId, c.menuCategoryName);
                      if (ok) await _deleteCategory(c.menuCategoryId, c.menuCategoryName);
                      return ok;
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFE0B2),
                          child: Icon(Icons.fastfood, color: Colors.orange),
                        ),
                        title: Text(c.menuCategoryName,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Mã loại: ${c.menuCategoryId}",
                            style: const TextStyle(color: Colors.black54)),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Colors.orange),
                          onPressed: () => _showDetail(c),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_filteredCategories.isNotEmpty)
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
