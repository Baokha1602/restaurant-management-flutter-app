import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  bool _isLoading = false;
  List<dynamic> _discounts = [];
  late final String discountApiUrl;
  late final String exchangeApiUrl;
  Set<String> _exchangedDiscounts = {}; // lưu mã đã đổi

  @override
  void initState() {
    super.initState();
    discountApiUrl = "${Config_URL.baseApiUrl}/DiscountApi";
    exchangeApiUrl = "${Config_URL.baseApiUrl}/DiscountApi/exchange";
    _fetchDiscounts();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  /// 🧩 Lấy danh sách discount khả dụng
  Future<void> _fetchDiscounts() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse(discountApiUrl),
        headers: {'Authorization': token},
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() => _discounts = data);
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 💎 Đổi điểm lấy mã giảm giá
  Future<void> _exchangeDiscount(String discountId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showSnack("Chưa đăng nhập!");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('user_id');
      if (customerId == null) {
        _showSnack("Không tìm thấy ID người dùng.");
        return;
      }

      final body = jsonEncode({
        "discountId": discountId,
        "customerId": customerId,
      });

      final res = await http.post(
        Uri.parse(exchangeApiUrl),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["isSuccess"] == true) {
          _showSnack("✅ ${data["message"] ?? "Đổi mã thành công!"}");
          setState(() {
            _exchangedDiscounts.add(discountId);
          });
        } else {
          _showSnack("❌ ${data["message"] ?? "Không thể đổi mã"}");
          if ((data["message"] ?? "").contains("đã đổi"))
            setState(() => _exchangedDiscounts.add(discountId));
        }
      } else {
        final msg = res.body.isNotEmpty
            ? jsonDecode(res.body)["message"] ?? "Lỗi server"
            : "Lỗi server";
        if (msg.contains("đã đổi")) {
          _showSnack("ℹ️ Bạn đã đổi mã này rồi.");
          setState(() => _exchangedDiscounts.add(discountId));
        } else {
          _showSnack("❌ $msg (${res.statusCode})");
        }
      }
    } catch (e) {
      _showSnack("⚠️ Lỗi khi đổi mã: $e");
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return Scaffold(

      backgroundColor: const Color(0xFFFFFBF5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: mainColor))
          : _discounts.isEmpty
          ? const Center(
          child: Text("Hiện chưa có mã giảm giá khả dụng.",
              style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _discounts.length,
        itemBuilder: (context, index) {
          final d = _discounts[index];
          final start = DateTime.parse(d["dateStart"]);
          final end = DateTime.parse(d["dateEnd"]);
          final now = DateTime.now();
          final isActive = d["discountStatus"] == true &&
              now.isAfter(start) &&
              now.isBefore(end);

          final discountId = d["discountId"];
          final discountName = d["discountName"] ?? "Không tên";
          final discountCategory = d["discountCategory"] ?? "N/A";
          final discountPrice = d["discountPrice"] ?? 0;
          final requiredPoints = d["requiredPoints"] ?? 0;

          final isExchanged = _exchangedDiscounts.contains(discountId);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: isActive
                ? Colors.white
                : Colors.grey.shade200,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                        mainColor.withOpacity(0.1),
                        child: const Icon(Icons.discount_rounded,
                            color: mainColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          discountName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isActive
                                ? Colors.black87
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("$discountCategory: $discountPrice",
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    "Cần $requiredPoints điểm để đổi",
                    style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hiệu lực: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}",
                    style: TextStyle(
                        fontSize: 13,
                        color: isActive
                            ? Colors.black54
                            : Colors.grey.shade600),
                  ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: (!isActive || isExchanged)
                          ? null
                          : () => _exchangeDiscount(discountId),
                      icon: const Icon(Icons.card_giftcard,
                          color: Colors.white),
                      label: Text(
                        isExchanged
                            ? "Đã đổi"
                            : "Đổi điểm",
                        style:
                        const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExchanged
                            ? Colors.grey
                            : mainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (isExchanged)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "🎉 Bạn đã đổi mã này rồi",
                        style: TextStyle(
                            color: Colors.green,
                            fontStyle: FontStyle.italic,
                            fontSize: 13),
                      ),
                    ),
                  if (!isActive)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "⏰ Mã này đã hết hiệu lực",
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontStyle: FontStyle.italic,
                            fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
