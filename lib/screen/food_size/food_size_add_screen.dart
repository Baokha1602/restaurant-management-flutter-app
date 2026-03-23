import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurantmanager/config/config_url.dart';

class FoodSizeAddScreen extends StatefulWidget {
  const FoodSizeAddScreen({super.key});

  @override
  State<FoodSizeAddScreen> createState() => _FoodSizeAddScreenState();
}

class _FoodSizeAddScreenState extends State<FoodSizeAddScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _foodNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController();
  final _menuSearchCtrl = TextEditingController();

  List<Map<String, dynamic>> _menuList = [];
  bool _isSearching = false;
  bool _isSubmitting = false;
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  int? _selectedMenuId;
  String? _selectedMenuName;

  final GlobalKey _menuFieldKey = GlobalKey();
  late final String apiUrl;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    apiUrl = "${Config_URL.baseApiUrl}/FoodSizeApi";
    _menuSearchCtrl.addListener(_onSearchChanged);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _menuSearchCtrl.removeListener(_onSearchChanged);
    _menuSearchCtrl.dispose();
    _foodNameCtrl.dispose();
    _priceCtrl.dispose();
    _sortOrderCtrl.dispose();
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

  // 🔍 Lắng nghe tìm kiếm realtime
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _menuSearchCtrl.text.trim();
      if (query.isEmpty) {
        _removeOverlay();
      } else {
        _fetchMenu(query);
      }
    });
  }

  // 🔄 Gọi API lấy danh sách món
  Future<void> _fetchMenu(String search) async {
    setState(() => _isSearching = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;
      final uri = Uri.parse("${Config_URL.baseApiUrl}/MenuApi?search=$search");
      debugPrint("📡 Gọi API: $uri");
      final res = await http.get(uri, headers: {'Authorization': token});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() => _menuList = List<Map<String, dynamic>>.from(data));
          _showOverlay();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi fetch menu: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // 🧭 Hiển thị danh sách gợi ý món
  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final box = _menuFieldKey.currentContext!.findRenderObject() as RenderBox;
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
            child: _menuList.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Không tìm thấy món nào",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            )
                : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _menuList.length,
                itemBuilder: (context, index) {
                  final menu = _menuList[index];
                  final name = menu['menuName'] ?? '';
                  final category = menu['menuCategoryName'] ?? '';

                  return InkWell(
                    onTap: () {
                      // ✅ Ngắt listener khi gán text
                      _menuSearchCtrl.removeListener(_onSearchChanged);
                      setState(() {
                        _selectedMenuId = menu['menuId'];
                        _selectedMenuName = name;
                        _menuSearchCtrl.text = name;
                      });
                      _removeOverlay();
                      FocusScope.of(context).unfocus();

                      // Gắn lại listener
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          _menuSearchCtrl.addListener(_onSearchChanged);
                        }
                      });
                    },
                    child: ListTile(
                      leading: const Icon(Icons.fastfood,
                          color: Colors.orange),
                      title: Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(category,
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

  // 🧾 Gửi request thêm kích cỡ
  Future<void> _createSize() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMenuId == null) {
      _showSnack("Vui lòng chọn món ăn!");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await _getBearerToken();
      if (token == null) return;

      final model = {
        "foodName": _foodNameCtrl.text.trim(),
        "menuId": _selectedMenuId,
        "price": double.tryParse(_priceCtrl.text.trim()) ?? 0,
        "sortOrder": int.tryParse(_sortOrderCtrl.text.trim()) ?? 0,
      };

      debugPrint("📤 Gửi model: $model");

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(model),
      );

      final data = jsonDecode(res.body);
      final isSuccess = data["isSuccess"] == true;
      final message = data["message"] ?? "Thao tác không thành công";

      _showSnack(message);

      if (isSuccess) {
        Navigator.pop(context, true); // ✅ Quay lại list và refresh
      }
    } catch (e) {
      _showSnack("Lỗi: $e");
    } finally {
      setState(() => _isSubmitting = false);
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
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
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
            "Thêm kích cỡ món ăn",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: mainColor,
          centerTitle: true,
          elevation: 2,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Icon(Icons.scale_rounded,
                    size: 90, color: Colors.orange.shade300),
                const SizedBox(height: 16),
                Text(
                  "Tạo kích cỡ mới cho món ăn",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 35),

                // 🔍 Chọn món ăn
                TextFormField(
                  key: _menuFieldKey,
                  controller: _menuSearchCtrl,
                  decoration: _inputStyle(
                    "Chọn món ăn",
                    Icons.restaurant_menu,
                    suffix: _isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.orange),
                      ),
                    )
                        : const Icon(Icons.arrow_drop_down,
                        color: Colors.orange),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng chọn món ăn" : null,
                ),
                const SizedBox(height: 20),

                // 🔹 Tên kích cỡ
                TextFormField(
                  controller: _foodNameCtrl,
                  decoration:
                  _inputStyle("Tên kích cỡ (S, M, L...)", Icons.rice_bowl),
                  validator: (v) => (v == null || v.isEmpty)
                      ? "Vui lòng nhập tên kích cỡ"
                      : null,
                ),
                const SizedBox(height: 20),

                // 🔹 Giá bán
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputStyle("Giá bán", Icons.attach_money),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng nhập giá bán" : null,
                ),
                const SizedBox(height: 20),

                // 🔹 Thứ tự hiển thị
                TextFormField(
                  controller: _sortOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputStyle("Thứ tự hiển thị", Icons.sort),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? "Vui lòng nhập thứ tự" : null,
                ),
                const SizedBox(height: 30),

                // 🔹 Nút lưu
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _createSize,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isSubmitting ? "Đang lưu..." : "Lưu kích cỡ",
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
