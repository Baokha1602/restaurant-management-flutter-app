import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Màu sắc chủ đạo
  static const Color primaryOrange = Color(0xFFFF7A00); // Cam chính
  static const Color lightOrange = Color(0xFFFFB74D); // Cam nhạt hơn
  static const Color darkOrange = Color(0xFFE65100);   // Cam đậm hơn
  static const Color textColor = Color(0xFF333333);    // Màu chữ đậm
  static const Color lightTextColor = Color(0xFF757575); // Màu chữ xám nhạt

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<Map<String, dynamic>> rawOrders = await _orderService.getOrderHistoryHasPayment();
      setState(() {
        _orders = rawOrders.map((json) => OrderModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể tải lịch sử đơn hàng: Vui lòng thử lại.";
        _isLoading = false;
      });
      debugPrint("🚨 Lỗi khi tải lịch sử đơn hàng: $e");
    }
  }

  Future<void> _showOrderDetails(int orderId) async {
    List<OrderDetailModel> details = [];
    String? errorDetailMessage;

    try {
      final List<Map<String, dynamic>> rawDetails = await _orderService.getOrderDetails(orderId);
      details = rawDetails.map((json) => OrderDetailModel.fromJson(json)).toList();
    } catch (e) {
      errorDetailMessage = "Không thể tải chi tiết đơn hàng.";
      debugPrint("🚨 Lỗi khi tải chi tiết đơn hàng: $e");
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép bottom sheet chiếm toàn màn hình nếu nội dung dài
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Chiếm 70% màn hình ban đầu
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Chi tiết đơn hàng #$orderId",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Divider(height: 20, thickness: 1, indent: 20, endIndent: 20),
                Expanded(
                  child: errorDetailMessage != null
                      ? Center(
                    child: Text(
                      errorDetailMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                      : details.isEmpty
                      ? const Center(
                    child: Text(
                      "Không có món ăn nào trong đơn hàng này.",
                      style: TextStyle(fontSize: 16, color: lightTextColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                      : ListView.builder(
                    controller: controller, // Quan trọng cho DraggableScrollableSheet
                    padding: const EdgeInsets.all(16.0),
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final detail = details[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              if (detail.urlImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.network(
                                    detail.urlImage!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                                        ),
                                  ),
                                ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detail.foodName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Số lượng: ${detail.quantity}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: lightTextColor,
                                      ),
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Đóng",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Không có AppBar để tránh trùng lặp
      backgroundColor: Colors.grey[100], // Màu nền tổng thể nhạt
      body: RefreshIndicator( // Thêm tính năng kéo xuống để làm mới
        onRefresh: _fetchOrderHistory,
        color: primaryOrange,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryOrange),
              const SizedBox(height: 15),
              const Text("Đang tải lịch sử đơn hàng...", style: TextStyle(color: lightTextColor)),
            ],
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textColor, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _fetchOrderHistory,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Thử lại"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        )
            : _orders.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, color: lightOrange, size: 80),
                const SizedBox(height: 25),
                const Text(
                  "Chưa có đơn hàng đã thanh toán nào trong lịch sử.",
                  style: TextStyle(fontSize: 18, color: lightTextColor, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Hãy bắt đầu đặt món để tích lũy điểm và nhận ưu đãi nhé!",
                  style: TextStyle(fontSize: 14, color: lightTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 6,
              shadowColor: primaryOrange.withOpacity(0.2), // Thêm shadow màu cam
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                onTap: () => _showOrderDetails(order.orderId),
                borderRadius: BorderRadius.circular(20),
                splashColor: lightOrange.withOpacity(0.3),
                highlightColor: lightOrange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Đơn hàng #${order.orderId}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryOrange,
                            ),
                          ),
                          Icon(Icons.chevron_right, color: lightTextColor, size: 28),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.calendar_today, "Ngày đặt:", DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)),
                      _buildInfoRow(Icons.payments, "Tổng tiền:", NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(order.totalAmount)),
                      _buildInfoRow(Icons.local_shipping, "Trạng thái đơn:", order.orderStatus),
                      _buildInfoRow(Icons.payment, "Trạng thái TT:", order.paymentStatus, color: order.paymentStatus == "Đã thanh toán" ? Colors.green.shade700 : primaryOrange),
                      if (order.paymentMethod != null)
                        _buildInfoRow(Icons.credit_card, "Phương thức:", order.paymentMethod!),
                      if (order.paymentDate != null)
                        _buildInfoRow(Icons.check_circle_outline, "Ngày TT:", DateFormat('dd/MM/yyyy HH:mm').format(order.paymentDate!)),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Nhấn để xem chi tiết",
                          style: TextStyle(fontSize: 13, color: lightTextColor.withOpacity(0.8), fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method để xây dựng hàng thông tin
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? primaryOrange.withOpacity(0.8)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                color: color ?? lightTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}