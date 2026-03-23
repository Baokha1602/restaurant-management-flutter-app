import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/config_url.dart';
import '../../models/menu_order.dart';
import '../../services/cart_service.dart';
import '../../services/menu_order_service.dart';
import '../cart/cart_details_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MenuOrderScreen extends StatefulWidget {
  const MenuOrderScreen({super.key});

  @override
  State<MenuOrderScreen> createState() => _MenuOrderScreenState();
}

class _MenuOrderScreenState extends State<MenuOrderScreen> with RouteAware {
  final MenuService _menuService = MenuService();
  final CartService _cartService = CartService();

  String formatCurrency(num value) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(value);
  }

  Map<String, dynamic>? _cartSummary;
  bool _isLoadingSummary = false;

  Future<void> _loadCartSummary() async {
    setState(() => _isLoadingSummary = true);
    final summary = await _cartService.getCartSummary();
    setState(() {
      _cartSummary = summary;
      _isLoadingSummary = false;
    });
  }

  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  Future<List<MenuOrderModel>>? _menusFuture;

  final Map<int, int> _selectedVariantIndex = {};
  final Map<int, int> _quantity = {};

  bool _isLoadingInit = true;

  @override
  void initState() {
    super.initState();
    _reloadAllData(); // 🔥 Khi mở trang lần đầu, load cả 2
  }

  /// ✅ Gọi lại toàn bộ khi quay về
  Future<void> _reloadAllData() async {
    await _initData();
    await _loadCartSummary();
  }

  Future<void> _initData() async {
    try {
      _categories = await _menuService.getMenuCategories();
      _selectedCategoryId = null;
      setState(() {
        _menusFuture =
            _menuService.getAvailableMenus(categoryId: _selectedCategoryId);
        _isLoadingInit = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInit = false;
      });
      debugPrint("🚨 Lỗi khởi tạo dữ liệu: $e");
    }
  }

  Future<void> _onCategoryChanged(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _menusFuture =
          _menuService.getAvailableMenus(categoryId: _selectedCategoryId);
    });
  }

  Future<void> _refreshMenus() async {
    await _reloadAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đăng ký route observer để lắng nghe khi quay lại trang
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// ✅ Gọi lại khi quay về từ trang khác
  @override
  void didPopNext() {
    _reloadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Order"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartDetailsScreen()),
          );
          // ✅ Sau khi quay lại, gọi lại toàn bộ dữ liệu
          _reloadAllData();
        },
        backgroundColor: Colors.orange,
        label: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _cartSummary != null
                  ? "${_cartSummary!['distinctFoodCount'] ?? 0}"
                  : "0",
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 10),
            Text(
              _cartSummary != null
                  ? formatCurrency(_cartSummary!['totalPrice'] ?? 0)
                  : "0₫",
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
      ),
      body: _isLoadingInit
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔸 Dropdown lọc loại món ăn
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Chọn loại món ăn",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem<int?>(
                value: cat["menuCategoryId"],
                child: Text(cat["menuCategoryName"]),
              ))
                  .toList(),
              onChanged: (value) {
                _onCategoryChanged(value);
              },
            ),
          ),

          // 🔸 Danh sách món ăn
          Expanded(
            child: _menusFuture == null
                ? const Center(
                child: Text("Đang tải dữ liệu món ăn..."))
                : FutureBuilder<List<MenuOrderModel>>(
              future: _menusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print(
                      "🚨 [MenuOrderScreen] Lỗi khi tải menu: ${snapshot.error}");
                  return const Center(
                    child: Text(
                      "Món ăn đã hết",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "Món ăn đã hết",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                final menus = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: _refreshMenus,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: menus.length,
                    itemBuilder: (context, index) {
                      final menu = menus[index];
                      int selectedIndex =
                          _selectedVariantIndex[menu.menuId] ?? 0;
                      if (selectedIndex >= menu.variants.length) {
                        selectedIndex = 0;
                        _selectedVariantIndex[menu.menuId] = 0;
                      }
                      final selectedVariant =
                      menu.variants[selectedIndex];
                      final quantity =
                          _quantity[menu.menuId] ?? 0;

                      final imageUrl = menu.images.isNotEmpty
                          ? (menu.images.first.startsWith("http")
                          ? menu.images.first
                          : "${Config_URL.baseUrl}/${menu.images.first}")
                          : "${Config_URL.baseUrl}/Image/Default/noimage.png";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color(0xFFFFF8F2),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imageUrl,
                                  width: 120, // ✅ ép chiều rộng cố định
                                  height: 120, // ✅ ép chiều cao cố định
                                  fit: BoxFit.cover, // ✅ đảm bảo ảnh không méo, cắt vừa khung
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.fastfood,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      menu.menuName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${selectedVariant.price.toStringAsFixed(0)}₫",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.orange,
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 6,
                                      children: List.generate(
                                          menu.variants.length,
                                              (vIndex) {
                                            final variant =
                                            menu.variants[vIndex];
                                            final isSelected =
                                                vIndex ==
                                                    selectedIndex;
                                            return ChoiceChip(
                                              label: Text(
                                                variant.foodSizeName,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              selected: isSelected,
                                              selectedColor:
                                              Colors.orange,
                                              onSelected: (_) {
                                                setState(() {
                                                  _selectedVariantIndex[
                                                  menu.menuId] =
                                                      vIndex;
                                                });
                                              },
                                            );
                                          }),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons
                                              .remove_circle_outline),
                                          onPressed: () async {
                                            final success = await _cartService
                                                .removeFromCart(
                                                selectedVariant
                                                    .foodSizeId);
                                            if (success) {
                                              setState(() {
                                                if ((_quantity[menu
                                                    .menuId] ??
                                                    0) >
                                                    0) {
                                                  _quantity[menu
                                                      .menuId] =
                                                  (_quantity[menu.menuId]! -
                                                      1);
                                                }
                                              });
                                              await _loadCartSummary();
                                            } else {
                                              ScaffoldMessenger.of(
                                                  context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "❌ Xóa món thất bại")),
                                              );
                                            }
                                          },
                                        ),
                                        Text(
                                          "${_quantity[menu.menuId] ?? 0}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons
                                              .add_circle_outline),
                                          onPressed: () async {
                                            final success = await _cartService
                                                .addToCart(
                                                selectedVariant
                                                    .foodSizeId);
                                            if (success) {
                                              setState(() {
                                                _quantity[menu
                                                    .menuId] =
                                                    (_quantity[menu.menuId] ??
                                                        0) +
                                                        1;
                                              });
                                              await _loadCartSummary();
                                            } else {
                                              ScaffoldMessenger.of(
                                                  context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "❌ Thêm món thất bại")),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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