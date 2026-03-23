import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/config_url.dart';
import '../../services/cart_service.dart';
import '../order/customer_order_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class CartDetailsScreen extends StatefulWidget {
  const CartDetailsScreen({super.key});

  @override
  State<CartDetailsScreen> createState() => _CartDetailsScreenState();
}

class _CartDetailsScreenState extends State<CartDetailsScreen> with RouteAware {
  final CartService _cartService = CartService();
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  String formatCurrency(num value) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(value);
  }

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  /// 🔁 Khi quay lại từ trang khác, load lại dữ liệu
  @override
  void didPopNext() {
    _loadCartItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    final items = await _cartService.getCartItems();
    setState(() {
      _cartItems = items;
      _isLoading = false;
    });
  }

  Future<void> _handleAdd(int foodSizeId) async {
    final success = await _cartService.addToCart(foodSizeId);
    if (success) await _loadCartItems();
  }

  Future<void> _handleRemove(int foodSizeId) async {
    final success = await _cartService.removeFromCart(foodSizeId);
    if (success) await _loadCartItems();
  }

  Future<void> _handleCreateOrder() async {
    final success = await _cartService.createOrder();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Tạo đơn hàng thành công!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerOrderScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Lỗi khi tạo đơn hàng!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _cartItems.fold<num>(0, (sum, item) => sum + (item['price'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng của bạn"),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCartItems, // ✅ Nút reload thủ công
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 💰 Tổng giá
          Container(
            width: double.infinity,
            color: Colors.green.shade100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "Tổng cộng: ${formatCurrency(total)}",
              style: const TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          // 📦 Danh sách món ăn (theo chiều dọc, giống bên Menu)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCartItems, // ✅ Kéo xuống để reload
              color: Colors.orange,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];

                  final imageUrl = (item['imageUrl'] != null &&
                      (item['imageUrl'] as String).isNotEmpty)
                      ? (item['imageUrl'].toString().startsWith('http')
                      ? item['imageUrl']
                      : "${Config_URL.baseUrl}/${item['imageUrl']}")
                      : "${Config_URL.baseUrl}/Image/Default/noimage.png";

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFFFFF8F2),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ảnh món ăn
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.fastfood, size: 50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Thông tin món ăn
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['menuName'] ?? "Không rõ tên",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Kích cỡ: ${item['foodSizeName'] ?? ''}",
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatCurrency(item['price'] ?? 0),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _handleRemove(item['foodSizeId']),
                                    ),
                                    Text(
                                      "${item['count'] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _handleAdd(item['foodSizeId']),
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
            ),
          ),

          // ✅ Nút xác nhận đơn hàng
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _handleCreateOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "XÁC NHẬN GIỎ HÀNG",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}