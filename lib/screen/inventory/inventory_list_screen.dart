import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';
import 'package:restaurantmanager/models/inventory_model.dart';
import 'package:restaurantmanager/screen/inventory/inventory_edit_screen.dart';
import 'package:restaurantmanager/screen/inventory/inventory_add_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Inventory> _inventories = [];
  bool _isLoading = false;

  late final String apiUrl;
  int _page = 1;
  final int _pageSize = 8;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/InventoryApi";
    _fetchInventories();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  // 🔍 Lắng nghe khi gõ tìm kiếm
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = _searchCtrl.text.trim();
      if (query.isEmpty) {
        _fetchInventories(); // load lại tất cả
      } else {
        _fetchInventories(search: query);
      }
    });
  }

  // 🔹 Gọi API lấy danh sách kho (có thể có search)
  Future<void> _fetchInventories({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getBearerToken();
      if (token == null) {
        debugPrint("⚠️ Token không tồn tại, vui lòng đăng nhập lại");
        return;
      }

      final uri = search != null && search.isNotEmpty
          ? Uri.parse(apiUrl).replace(queryParameters: {"search": search})
          : Uri.parse(apiUrl);

      debugPrint("📡 Gọi API: $uri");

      final res = await http.get(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _inventories = data.map((e) => Inventory.fromJson(e)).toList();
            _page = 1;
          });
          debugPrint("✅ Nhận được ${_inventories.length} bản ghi");
        } else {
          debugPrint("⚠️ API không trả về danh sách hợp lệ: $data");
        }
      } else {
        debugPrint("❌ Lỗi API ${res.statusCode}: ${res.body}");
        _showSnack("Không thể tải dữ liệu (${res.statusCode})");
      }
    } catch (e) {
      debugPrint("🚨 Lỗi fetchInventories: $e");
      _showSnack("Lỗi tải dữ liệu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteInventory(int id, String menuName) async {
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final uri = Uri.parse("$apiUrl/$id");
      final res = await http.delete(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        setState(() => _inventories.removeWhere((e) => e.inventoryId == id));
        _showSnack("Đã xóa $menuName khỏi kho");
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Xác nhận xóa",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc muốn xóa '$name' khỏi kho?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text("Xóa", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  List<Inventory> get _pagedInventories {
    final start = (_page - 1) * _pageSize;
    final end = (_page * _pageSize).clamp(0, _inventories.length);
    return _inventories.sublist(start, end);
  }

  int get _totalPages => (_inventories.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text("Quản lý kho",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          backgroundColor: mainColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Thêm tồn kho",
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryAddScreen()),
            );
            if (added == true) _fetchInventories();
          },
        ),
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
                    color: mainColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm món ăn...",
                  hintStyle:
                  TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  prefixIcon: const Icon(Icons.search, color: mainColor),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                child:
                CircularProgressIndicator(color: Colors.orange))
                : _inventories.isEmpty
                ? const Center(
                child: Text("Không có dữ liệu tồn kho",
                    style: TextStyle(
                        color: Colors.black54, fontSize: 16)))
                : ListView.builder(
              itemCount: _pagedInventories.length,
              itemBuilder: (_, i) {
                final item = _pagedInventories[i];
                return Dismissible(
                  key: Key(item.inventoryId.toString()),
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
                    await _askConfirmDelete(item.menuName);
                    if (ok) {
                      await _deleteInventory(
                          item.inventoryId, item.menuName);
                    }
                    return ok;
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    elevation: 3,
                    shadowColor: Colors.orange.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(Icons.inventory_2,
                            color: Colors.orange),
                      ),
                      title: Text(item.menuName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      subtitle: Text(
                        "Kích cỡ: ${item.foodSizeName}\nSố lượng: ${item.quantity} ${item.unit}",
                        style: const TextStyle(
                            color: Colors.black87, height: 1.4),
                      ),
                      onLongPress: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InventoryEditScreen(inventory: item),
                          ),
                        );
                        if (updated == true) _fetchInventories();
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          if (_inventories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 6,
                children: List.generate(_totalPages, (index) {
                  final pageNum = index + 1;
                  final active = pageNum == _page;
                  return ElevatedButton(
                    onPressed: () => setState(() => _page = pageNum),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      active ? mainColor : Colors.grey.shade300,
                      foregroundColor:
                      active ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text(pageNum.toString(),
                        style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
