import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/config_url.dart';
import '../../services/order_service.dart';
import '../payment/user_confirmpayment.dart';


class CustomerOrderScreen extends StatefulWidget {
  const CustomerOrderScreen({super.key});

  @override
  State<CustomerOrderScreen> createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends State<CustomerOrderScreen> {
  final OrderService _orderService = OrderService();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchOrders();
  }


  /// 🟢 Lắng nghe socket thay đổi trạng thái đơn
  Future<void> _initSocket() async {
    debugPrint("🚀 [Socket] Bắt đầu kết nối SignalR...");

    _orderService.onOrderStatusChanged = (data) {
      final orderId = data['OrderId'];
      final newStatus = data['NewStatus'];
      debugPrint("📩 [Socket] Đơn #$orderId cập nhật → $newStatus");

      setState(() {
        final index = _orders.indexWhere((o) => o['orderId'] == orderId);
        if (index != -1) _orders[index]['orderStatus'] = newStatus;
      });
    };

    await _orderService.connect();
    debugPrint("✅ [Socket] Đã kết nối đến Hub thành công (User)");
    setState(() => _isConnected = true);
  }


  /// 🔹 Gọi API lấy danh sách đơn hàng
  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final data = await _orderService.getMyOrders();
    setState(() {
      _orders = data;
      _isLoading = false;
    });
  }

  /// 🔹 Gọi API yêu cầu thanh toán
  Future<void> _requestPayment(int orderId) async {
    final result = await _orderService.requestPayment(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['isSuccess'] ? Colors.green : Colors.red,
        ),
      );
      if (result['isSuccess']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConfirmPayment()),
        );
      }
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "";
    final date = DateTime.tryParse(dateString);
    if (date == null) return "";
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String formatCurrency(num value) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

  @override
  void dispose() {
    _orderService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        title: const Text(
          "Đơn hàng của tôi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
        ],
      ),

      // 🧡 Nội dung chính
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
        color: Colors.orange,
        onRefresh: _fetchOrders,
        child: _orders.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                "Bạn chưa có đơn hàng nào.",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        )
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            final orderDetails = order['orderDetail'] as List?;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bàn: ${order['tableName'] ?? 'Không xác định'}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text("Mã đơn hàng: #${order['orderId']}",
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 6),
                  Text("Khách hàng: ${order['customerName']}",
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text("Trạng thái đơn: ",
                          style: TextStyle(fontSize: 15)),
                      Text(
                        order['orderStatus'],
                        style: const TextStyle(
                            fontSize: 15,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("Thanh toán: ${order['paymentStatus']}",
                      style: const TextStyle(
                          fontSize: 15, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                      "Ngày đặt: ${formatDate(order['orderDate'])}",
                      style: const TextStyle(
                          fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    "Tổng tiền: ${formatCurrency(order['totalAmount'] ?? 0)}",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 14),

                  // Danh sách món
                  if (orderDetails != null &&
                      orderDetails.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.orangeAccent, width: 0.8),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text("Danh sách món:",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...orderDetails.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.05),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    child: item['urlImage'] != null
                                        ? Image.network(
                                      "${Config_URL.baseUrl}/${item['urlImage']}",
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                        : Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors
                                          .grey.shade300,
                                      child: const Icon(
                                          Icons.fastfood,
                                          color:
                                          Colors.orange),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['foodName'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                              FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Số lượng: ${item['quantity']}",
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  // 🔸 Nút yêu cầu thanh toán cho từng đơn
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _requestPayment(order['orderId']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Yêu cầu thanh toán",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
