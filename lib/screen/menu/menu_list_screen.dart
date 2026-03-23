import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';
import 'package:restaurantmanager/models/menu_model.dart';
import 'menu_add_screen.dart';
import 'menu_edit_screen.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<MenuModel> _menus = [];
  bool _isLoading = false;
  Timer? _debounce;
  late final String apiUrl;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/MenuApi";
    _fetchMenus(); // load initial data
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ✅ Xử lý tìm kiếm realtime
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = _searchCtrl.text;
      if (query.isEmpty) {
        _fetchMenus();
      } else {
        _fetchMenus(search: query);
      }
    });
  }

  // ✅ Lấy token Bearer
  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  // ✅ Gọi API lấy danh sách món
  Future<void> _fetchMenus({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      String url = apiUrl;
      if (search != null && search.isNotEmpty) {
        url += "?search=${Uri.encodeComponent(search)}";
      }

      final res = await http.get(Uri.parse(url), headers: {'Authorization': token});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _menus = data.map((e) => MenuModel.fromJson(e)).toList();
          });
        }
      } else if (res.statusCode == 401) {
        _showSnack("Phiên đăng nhập hết hạn (401)");
      } else {
        _showSnack("Không thể tải dữ liệu (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi tải dữ liệu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Xóa món ăn
  Future<void> _deleteMenu(int id, String name) async {
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final uri = Uri.parse("$apiUrl/$id");
      final res = await http.delete(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        setState(() => _menus.removeWhere((e) => e.menuId == id));
        _showSnack("Đã xóa món '$name'");
      } else {
        _showSnack("Xóa thất bại (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi xóa: $e");
    }
  }

  Future<bool> _askConfirmDelete(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận xóa",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc muốn xóa món '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text("Xóa", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ✅ Popup chi tiết món ăn (hiển thị ảnh chính và danh sách ảnh nếu có)
  void _showDetail(MenuModel m) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (m.mainImageUrl != null && m.mainImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    Config_URL.baseUrl + m.mainImageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                m.menuName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text("Loại: ${m.menuCategoryName}",
                  style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 8),
              Text(
                m.detail?.isNotEmpty == true ? m.detail! : "Không có mô tả",
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              if (m.imageUrls != null && m.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: m.imageUrls!
                      .map((url) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      Config_URL.baseUrl + url,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ))
                      .toList(),
                )
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("Đóng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text(
          "Quản lý món ăn",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm món ăn",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuAddScreen()),
          );
          if (added == true) _fetchMenus();
        },
      ),
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm món ăn...",
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ),

          // 📋 Danh sách món ăn
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(color: Colors.orange))
                : _menus.isEmpty
                ? const Center(child: Text("Không có dữ liệu món ăn"))
                : ListView.builder(
              itemCount: _menus.length,
              itemBuilder: (_, i) {
                final m = _menus[i];
                return Dismissible(
                  key: Key(m.menuId.toString()),
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
                    final ok = await _askConfirmDelete(m.menuName);
                    if (ok) await _deleteMenu(m.menuId, m.menuName);
                    return ok;
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    elevation: 3,
                    shadowColor: Colors.orange.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: m.mainImageUrl != null &&
                            m.mainImageUrl!.isNotEmpty
                            ? Image.network(
                          Config_URL.baseUrl + m.mainImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 60,
                          height: 60,
                          color: Colors.orange.shade50,
                          child: const Icon(Icons.fastfood,
                              color: Colors.orange, size: 26),
                        ),
                      ),
                      title: Text(
                        m.menuName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      subtitle: Text(
                        "Loại: ${m.menuCategoryName}\n${m.detail ?? ''}",
                        style: const TextStyle(
                            color: Colors.black87, height: 1.4),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline,
                            color: Colors.orange),
                        onPressed: () => _showDetail(m),
                      ),
                      onLongPress: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MenuEditScreen(menu: m.toJson()),
                          ),
                        );
                        if (updated == true) _fetchMenus();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
