import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';
import 'package:restaurantmanager/models/discount_model.dart';
import 'discount_add_screen.dart';
import 'discount_edit_screen.dart';

class DiscountListScreen extends StatefulWidget {
  const DiscountListScreen({super.key});

  @override
  State<DiscountListScreen> createState() => _DiscountListScreenState();
}

class _DiscountListScreenState extends State<DiscountListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<DiscountModel> _discounts = [];
  bool _isLoading = false;
  Timer? _debounce;
  late final String apiUrl;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/DiscountApi";
    _fetchDiscounts();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchDiscounts(search: _searchCtrl.text.trim());
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _fetchDiscounts({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final uri = Uri.parse(
        "$apiUrl${search != null && search.isNotEmpty ? '?search=$search' : ''}",
      );
      final res = await http.get(uri, headers: {'Authorization': token});

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _discounts = data.map((e) => DiscountModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      _showSnack("Lỗi tải dữ liệu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Xác nhận xóa",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc muốn xóa mã '$name'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy")),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text("Xóa",
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _deleteDiscount(String id, String name) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.delete(
        Uri.parse("$apiUrl/$id"),
        headers: {'Authorization': token},
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() => _discounts.removeWhere((e) => e.discountId == id));
        _showSnack("✅ Đã xóa mã '$name'");
      } else {
        _showSnack("❌ Xóa thất bại (${res.statusCode})");
      }
    } catch (e) {
      _showSnack("Lỗi xóa: $e");
    }
  }

  // 🔍 UI xem chi tiết
  void _showDetail(DiscountModel d) {
    final start = DateTime.parse(d.dateStart);
    final end = DateTime.parse(d.dateEnd);
    final now = DateTime.now();
    final isActive =
        d.discountStatus && now.isAfter(start) && now.isBefore(end);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [Colors.orange.shade50, Colors.white]
                  : [Colors.grey.shade200, Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.local_offer : Icons.block,
                color: isActive ? Colors.orange : Colors.grey,
                size: 70,
              ),
              const SizedBox(height: 8),
              Text(
                d.discountName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 10),
              Divider(thickness: 1, color: Colors.grey.shade300),
              _detailRow(Icons.category, "Loại", d.discountCategory),
              _detailRow(Icons.price_change, "Giá trị", "${d.discountPrice}"),
              _detailRow(
                  Icons.star, "Điểm cần đổi", d.requiredPoints.toString()),
              _detailRow(
                Icons.calendar_today,
                "Hiệu lực",
                "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}",
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color:
                  isActive ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? "Còn hiệu lực" : "Hết hiệu lực",
                  style: TextStyle(
                    color: isActive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text("Đóng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text(
          "Quản lý mã giảm giá",
          style:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 3,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainColor,
        icon: const Icon(Icons.add),
        label: const Text("Thêm mã"),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiscountAddScreen()),
          );
          if (added == true) _fetchDiscounts();
        },
      ),
      body: Column(
        children: [
          // 🔎 Thanh tìm kiếm đẹp
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
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Tìm mã giảm giá...",
                  hintStyle:
                  TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  prefixIcon:
                  const Icon(Icons.search, color: Colors.orange),
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
                : _discounts.isEmpty
                ? const Center(child: Text("Không có dữ liệu"))
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _discounts.length,
              itemBuilder: (_, i) {
                final d = _discounts[i];
                final now = DateTime.now();
                final start = DateTime.parse(d.dateStart);
                final end = DateTime.parse(d.dateEnd);
                final isActive = d.discountStatus &&
                    now.isAfter(start) &&
                    now.isBefore(end);

                return Dismissible(
                  key: Key(d.discountId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    final ok = await _confirmDelete(d.discountName);
                    if (ok) {
                      await _deleteDiscount(
                          d.discountId, d.discountName);
                    }
                    return ok;
                  },
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? [Colors.orange.shade50, Colors.white]
                            : [Colors.grey.shade200, Colors.grey.shade100],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isActive
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.black12,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: isActive
                            ? mainColor.withOpacity(0.15)
                            : Colors.grey.shade400,
                        child: Icon(
                          Icons.local_offer_rounded,
                          color: isActive
                              ? mainColor
                              : Colors.grey.shade700,
                        ),
                      ),
                      title: Text(
                        d.discountName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isActive
                              ? Colors.black
                              : Colors.grey.shade700,
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                        const EdgeInsets.only(top: 4),
                        child: Text(
                          "${d.discountCategory}: ${d.discountPrice}\nĐiểm cần đổi: ${d.requiredPoints}\n${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}",
                          style: TextStyle(
                            height: 1.4,
                            color: isActive
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline,
                            color: Colors.orange),
                        onPressed: () => _showDetail(d),
                      ),
                      onLongPress: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DiscountEditScreen(discount: d),
                          ),
                        );
                        if (updated == true) _fetchDiscounts();
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
