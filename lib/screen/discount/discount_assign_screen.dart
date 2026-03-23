import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';

class DiscountAssignScreen extends StatefulWidget {
  const DiscountAssignScreen({super.key});

  @override
  State<DiscountAssignScreen> createState() => _DiscountAssignScreenState();
}

class _DiscountAssignScreenState extends State<DiscountAssignScreen> {
  bool _isLoading = false;
  String? _selectedUserId;
  String? _selectedDiscountId;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _discounts = [];

  // Controllers + Overlay
  final _userCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final GlobalKey _userFieldKey = GlobalKey();
  final GlobalKey _discountFieldKey = GlobalKey();

  OverlayEntry? _userOverlay;
  OverlayEntry? _discountOverlay;

  List<Map<String, dynamic>> _userSuggestions = [];
  List<Map<String, dynamic>> _discountSuggestions = [];

  bool _userSearching = false;
  bool _discountSearching = false;

  late final String userApiUrl;
  late final String discountApiUrl;
  late final String assignApiUrl;

  @override
  void initState() {
    super.initState();
    userApiUrl = "${Config_URL.baseApiUrl}/CustomerApi/GetAllCustomer";
    discountApiUrl = "${Config_URL.baseApiUrl}/DiscountApi";
    assignApiUrl = "${Config_URL.baseApiUrl}/DiscountCustomerApi/assign";
    _fetchUsersAndDiscounts();

    _userCtrl.addListener(_onUserChanged);
    _discountCtrl.addListener(_onDiscountChanged);
  }

  @override
  void dispose() {
    _userCtrl.removeListener(_onUserChanged);
    _discountCtrl.removeListener(_onDiscountChanged);
    _userCtrl.dispose();
    _discountCtrl.dispose();
    _userOverlay?.remove();
    _discountOverlay?.remove();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  Future<void> _fetchUsersAndDiscounts() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) {
        _showSnack("⚠️ Chưa đăng nhập.");
        return;
      }
      final usersRes =
      await http.get(Uri.parse(userApiUrl), headers: {'Authorization': token});
      final discountsRes =
      await http.get(Uri.parse(discountApiUrl), headers: {'Authorization': token});

      if (usersRes.statusCode == 200 && discountsRes.statusCode == 200) {
        final usersData = jsonDecode(usersRes.body);
        final disData = jsonDecode(discountsRes.body);
        setState(() {
          _users = (usersData as List).map((e) => Map<String, dynamic>.from(e)).toList();
          _discounts = (disData as List).map((e) => Map<String, dynamic>.from(e)).toList();
          _userSuggestions = _users;
          _discountSuggestions = _discounts;
        });
      } else {
        _showSnack("❌ Không thể tải dữ liệu (${usersRes.statusCode}/${discountsRes.statusCode})");
      }
    } catch (e) {
      _showSnack("⚠️ Lỗi tải dữ liệu: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================ Realtime Filter ============================
  void _onUserChanged() {
    final q = _userCtrl.text.trim().toLowerCase();
    setState(() => _userSearching = true);
    Future.microtask(() {
      final filtered = q.isEmpty
          ? _users
          : _users.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
      setState(() {
        _userSuggestions = filtered;
        _userSearching = false;
      });
      _showOverlay(_userFieldKey, filtered, isUser: true);
    });
  }

  void _onDiscountChanged() {
    final q = _discountCtrl.text.trim().toLowerCase();
    setState(() => _discountSearching = true);
    Future.microtask(() {
      final filtered = q.isEmpty
          ? _discounts
          : _discounts.where((d) {
        final name = (d['discountName'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
      setState(() {
        _discountSuggestions = filtered;
        _discountSearching = false;
      });
      _showOverlay(_discountFieldKey, filtered, isUser: false);
    });
  }

  void _showOverlay(GlobalKey key, List<Map<String, dynamic>> data, {required bool isUser}) {
    _removeOverlay(isUser);
    final overlay = Overlay.of(context);
    if (overlay == null || key.currentContext == null) return;
    final box = key.currentContext!.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: pos.dx,
        top: pos.dy + box.size.height + 4,
        width: box.size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              padding: EdgeInsets.zero,
              children: data.map((item) {
                final name = isUser
                    ? (item['name'] ?? item['email'] ?? 'Người dùng').toString()
                    : (item['discountName'] ?? 'Mã giảm giá').toString();
                final sub = isUser
                    ? (item['email'] ?? '').toString()
                    : (item['discountCategory'] ?? '').toString();

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isUser ? Icons.person : Icons.local_offer,
                    color: Colors.orange,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: sub.isNotEmpty ? Text(sub) : null,
                  onTap: () {
                    setState(() {
                      if (isUser) {
                        _selectedUserId = item['customerId'] ?? item['id'];
                        _userCtrl.text = name;
                      } else {
                        _selectedDiscountId = item['discountId'];
                        _discountCtrl.text = name;
                      }
                    });
                    _removeOverlay(isUser);
                    FocusScope.of(context).unfocus();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    if (isUser) {
      _userOverlay = entry;
    } else {
      _discountOverlay = entry;
    }
    overlay.insert(entry);
  }

  void _removeOverlay(bool isUser) {
    if (isUser) {
      _userOverlay?.remove();
      _userOverlay = null;
    } else {
      _discountOverlay?.remove();
      _discountOverlay = null;
    }
  }

  // ============================ Assign ============================
  Future<void> _assignDiscount() async {
    if (_selectedUserId == null || _selectedDiscountId == null) {
      _showSnack("⚠️ Hãy chọn người dùng và mã giảm giá.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) {
        _showSnack("⚠️ Chưa đăng nhập.");
        return;
      }
      final res = await http.post(
        Uri.parse(assignApiUrl),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({
          "discountId": _selectedDiscountId,
          "customerId": _selectedUserId,
        }),
      );
      if (res.statusCode == 200) {
        _showSnack("✅ Gán mã giảm giá thành công!");
      } else {
        _showSnack("❌ Lỗi (${res.statusCode}): ${res.body}");
      }
    } catch (e) {
      _showSnack("⚠️ Lỗi khi gán mã: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ============================ UI ============================
  InputDecoration _inputStyle(String hint, IconData icon, bool loading) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.orange),
      suffixIcon: loading
          ? const Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )
          : const Icon(Icons.search, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.orange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return GestureDetector(
      onTap: () {
        _removeOverlay(true);
        _removeOverlay(false);
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80), Color(0xFFFFB74D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: mainColor))
                : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AppBar tuỳ chỉnh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                      ),
                      const Text(
                        "Gán mã giảm giá",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("👤 Người dùng",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextField(
                            key: _userFieldKey,
                            controller: _userCtrl,
                            decoration: _inputStyle(
                                "Nhập tên hoặc email để tìm...",
                                Icons.person,
                                _userSearching),
                          ),
                          const SizedBox(height: 24),

                          const Text("🎁 Mã giảm giá",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextField(
                            key: _discountFieldKey,
                            controller: _discountCtrl,
                            decoration: _inputStyle(
                                "Nhập tên mã để tìm...",
                                Icons.local_offer,
                                _discountSearching),
                          ),
                          const Spacer(),

                          // Nút
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                              _isLoading ? null : _assignDiscount,
                              icon: const Icon(Icons.card_giftcard,
                                  color: Colors.white),
                              label: Text(
                                _isLoading
                                    ? "Đang gán..."
                                    : "Gán mã giảm giá",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mainColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
