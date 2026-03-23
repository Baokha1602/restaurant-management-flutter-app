import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:restaurantmanager/config/config_url.dart';
import 'package:restaurantmanager/models/food_size_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_size_add_screen.dart';
import 'food_size_edit_screen.dart';

class FoodSizeListScreen extends StatefulWidget {
  const FoodSizeListScreen({super.key});

  @override
  State<FoodSizeListScreen> createState() => _FoodSizeListScreenState();
}

class _FoodSizeListScreenState extends State<FoodSizeListScreen> {
  List<FoodSize> _sizes = [];
  bool _isLoading = false;

  late final String apiUrl;
  int _page = 1;
  final int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/FoodSizeApi";
    _fetchSizes();
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _fetchSizes() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;
      final res = await http.get(Uri.parse(apiUrl), headers: {'Authorization': token});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() => _sizes = data.map((e) => FoodSize.fromJson(e)).toList());
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

  Future<void> _deleteSize(int id, String name) async {
    try {
      final token = await _getBearerToken();
      if (token == null) return;
      final uri = Uri.parse("$apiUrl/$id");
      final res = await http.delete(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        setState(() => _sizes.removeWhere((e) => e.foodSizeId == id));
        _showSnack("Đã xóa biến thể '$name'");
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận xóa", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc muốn xóa kích cỡ '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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

  void _showDetail(FoodSize size) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFFFE0B2),
              child: Icon(Icons.rice_bowl, color: Colors.orange, size: 38),
            ),
            const SizedBox(height: 12),
            Text(size.foodName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 6),
            Text("Thuộc món: ${size.menuName}",
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text("Giá bán: ${size.price.toStringAsFixed(0)} đ",
                style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 6),
            Text("Thứ tự hiển thị: ${size.sortOrder}",
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text("Đóng"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
      ),
    );
  }

  List<FoodSize> get _pagedSizes {
    final start = (_page - 1) * _pageSize;
    final end = (_page * _pageSize).clamp(0, _sizes.length);
    return _sizes.sublist(start, end);
  }

  int get _totalPages => (_sizes.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text("Quản lý kích cỡ món ăn",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: mainColor,
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          backgroundColor: mainColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Thêm kích cỡ",
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoodSizeAddScreen()),
            );
            if (added == true) _fetchSizes();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _sizes.isEmpty
          ? const Center(
          child: Text("Không có dữ liệu kích cỡ món ăn",
              style: TextStyle(color: Colors.black54, fontSize: 16)))
          : Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _pagedSizes.length,
              itemBuilder: (_, i) {
                final fs = _pagedSizes[i];
                return Dismissible(
                  key: Key(fs.foodSizeId.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    final ok = await _askConfirmDelete(fs.foodSizeId, fs.foodName);
                    if (ok) await _deleteSize(fs.foodSizeId, fs.foodName);
                    return ok;
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    elevation: 3,
                    shadowColor: Colors.orange.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.orange.shade50,
                        child: const Icon(Icons.rice_bowl,
                            color: Colors.orange, size: 26),
                      ),
                      title: Text(fs.foodName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(
                        "${fs.menuName}\nGiá: ${fs.price.toStringAsFixed(0)} đ",
                        style: const TextStyle(color: Colors.black87, height: 1.4),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.orange),
                        onPressed: () => _showDetail(fs),
                      ),
                      onLongPress: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  FoodSizeEditScreen(foodSize: fs.toJson())),
                        );
                        if (updated == true) _fetchSizes();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          if (_sizes.isNotEmpty)
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
                      padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(pageNum.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
