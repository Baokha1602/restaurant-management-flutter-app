import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';

class InventoryAddScreen extends StatefulWidget {
  const InventoryAddScreen({super.key});

  @override
  State<InventoryAddScreen> createState() => _InventoryAddScreenState();
}

class _InventoryAddScreenState extends State<InventoryAddScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _unitCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _foodSearchCtrl = TextEditingController();

  List<Map<String, dynamic>> _foodList = [];
  bool _isSearching = false;
  bool _isSaving = false;
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  int? _selectedFoodSizeId;

  final GlobalKey _foodFieldKey = GlobalKey();
  late final String apiUrl;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/InventoryApi";
    _foodSearchCtrl.addListener(_onSearchChanged);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _foodSearchCtrl.removeListener(_onSearchChanged);
    _foodSearchCtrl.dispose();
    _unitCtrl.dispose();
    _quantityCtrl.dispose();
    _overlayEntry?.remove();
    _debounce?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('jwt_token');
    if (raw == null) return null;
    return raw.startsWith('Bearer ') ? raw : 'Bearer $raw';
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _foodSearchCtrl.text.trim();
      if (query.isEmpty) {
        _removeOverlay();
      } else {
        _fetchFood(query);
      }
    });
  }

  Future<void> _fetchFood(String search) async {
    setState(() => _isSearching = true);
    try {
      final token = await _getBearerToken();
      if (token == null) {
        _showSnack("Token không hợp lệ, vui lòng đăng nhập lại.");
        return;
      }

      final uri =
      Uri.parse("${Config_URL.baseApiUrl}/FoodSizeApi?search=$search");
      debugPrint("📡 Gọi API: $uri");
      final res = await http.get(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() => _foodList = List<Map<String, dynamic>>.from(data));
          _showOverlay();
        }
      } else if (res.statusCode == 401) {
        _showSnack("Phiên đăng nhập hết hạn (401)");
      } else {
        _showSnack("Lỗi tải dữ liệu (${res.statusCode})");
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi tải danh sách món ăn: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final box = _foodFieldKey.currentContext!.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + box.size.height + 4,
        width: box.size.width,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: _foodList.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Không tìm thấy món nào",
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(color: Colors.black54, fontSize: 14)),
            )
                : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _foodList.length,
                itemBuilder: (context, index) {
                  final food = _foodList[index];
                  final menuName = food['menuName'] ?? '';
                  final sizeName = food['foodName'] ?? '';
                  final price = food['price']?.toString() ?? "0";
                  final foodSizeId = food['foodSizeId'];

                  return InkWell(
                    onTap: () {
                      // 🧠 Fix lỗi “Không tìm thấy món nào” sau khi chọn
                      _foodSearchCtrl.removeListener(_onSearchChanged);
                      setState(() {
                        _foodSearchCtrl.text = "$menuName - $sizeName";
                        _selectedFoodSizeId = foodSizeId;
                      });
                      _removeOverlay();
                      FocusScope.of(context).unfocus();

                      // Gắn lại listener sau một khoảng nhỏ
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          _foodSearchCtrl.addListener(_onSearchChanged);
                        }
                      });
                    },
                    child: ListTile(
                      leading: const Icon(Icons.fastfood,
                          color: Colors.orange),
                      title: Text(
                        "$menuName - $sizeName",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text("Giá: ${price}đ",
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    _animCtrl.forward(from: 0);
  }

  void _removeOverlay() {
    _animCtrl.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFoodSizeId == null) {
      _showSnack("Vui lòng chọn món ăn!");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final model = {
        "foodSizeId": _selectedFoodSizeId,
        "unit": _unitCtrl.text.trim(),
        "quantity": int.tryParse(_quantityCtrl.text.trim()) ?? 0,
      };

      debugPrint("📤 Gửi model: $model");

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(model),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["isSuccess"] == true) {
        _showSnack("✅ ${data["message"] ?? "Thêm thành công!"}");
        Navigator.pop(context, true);
      } else {
        _showSnack("❌ ${data["message"] ?? "Thêm thất bại!"}");
      }
    } catch (e) {
      _showSnack("⚠️ Lỗi: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _inputStyle(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2)),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;

    return GestureDetector(
      onTap: _removeOverlay,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        appBar: AppBar(
          title: const Text(
            "Thêm tồn kho",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: mainColor,
          centerTitle: true,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Icon(Icons.inventory_2_outlined,
                    size: 90, color: Colors.orange.shade300),
                const SizedBox(height: 16),
                Text(
                  "Nhập thêm hàng tồn kho",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 35),

                // 🔽 Ô chọn món ăn / kích cỡ
                TextFormField(
                  key: _foodFieldKey,
                  controller: _foodSearchCtrl,
                  decoration: _inputStyle(
                    "Chọn món ăn / kích cỡ",
                    Icons.restaurant_menu,
                    suffix: _isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.orange)),
                    )
                        : const Icon(Icons.arrow_drop_down,
                        color: Colors.orange),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng chọn món ăn" : null,
                ),
                const SizedBox(height: 20),

                // 🔹 Đơn vị
                TextFormField(
                  controller: _unitCtrl,
                  decoration:
                  _inputStyle("Đơn vị (VD: Ly, Dĩa...)", Icons.scale),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng nhập đơn vị" : null,
                ),
                const SizedBox(height: 20),

                // 🔹 Số lượng
                TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputStyle("Số lượng", Icons.numbers),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng nhập số lượng" : null,
                ),
                const SizedBox(height: 30),

                // 🔹 Nút lưu
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isSaving ? "Đang lưu..." : "Lưu tồn kho",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
