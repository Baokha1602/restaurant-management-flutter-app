import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';
import 'order_detail_screen.dart';

class OrderReceivedScreen extends StatefulWidget {
  const OrderReceivedScreen({super.key});

  @override
  State<OrderReceivedScreen> createState() => _OrderReceivedScreenState();
}

class _OrderReceivedScreenState extends State<OrderReceivedScreen> {
  List<Map<String, dynamic>> _orders = [];
  final OrderService _orderService = OrderService();
  bool _isConnected = false;
  bool _isLoading = false;

  final Map<int, String> _orderStatuses = {};

  String formatCurrency(num value) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

  String formatDate(dynamic dateInput) {
    if (dateInput == null) return "";
    DateTime? date;
    if (dateInput is String) {
      date = DateTime.tryParse(dateInput);
    } else if (dateInput is DateTime) {
      date = dateInput;
    }
    if (date == null) return "";
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  void initState() {
    super.initState();
    _setupHubConnection();
    _reloadOrders(); // ✅ tải dữ liệu ban đầu
  }

  // 🟠 Kết nối socket
  void _setupHubConnection() async {
    _orderService.onNewOrder = (data) {
      setState(() {
        _orders.insert(0, data);
        final int orderId = data['orderId'] ?? 0;
        _orderStatuses[orderId] = "Tiếp nhận đơn";
      });
    };
    await _orderService.connect();
    setState(() => _isConnected = true);
  }

  // 🟠 Gọi API lấy danh sách đơn hàng
  Future<void> _reloadOrders() async {
    setState(() => _isLoading = true);
    final newOrders = await _orderService.getAllOrders();

    setState(() {
      _orders = newOrders;
      _orderStatuses.clear();
      for (var o in newOrders) {
        final id = o['orderId'];
        _orderStatuses[id] = o['orderStatus'] ?? 'Tiếp nhận đơn';
      }
      _isLoading = false;
    });
  }

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
          "Đơn hàng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 🔁 Nút tải lại dữ liệu
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Tải lại danh sách",
            onPressed: _reloadOrders,
          ),
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: _orders.isEmpty
            ? const Center(
          child: Text(
            "⏳ Chưa có đơn mới",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            final int orderId = order['orderId'] ?? 0;
            final String tableName =
                order['tableName'] ?? 'Không xác định';
            final dynamic orderDate = order['orderDate'];
            final rawAmount = order['totalAmount'];
            final num totalAmount = rawAmount is num
                ? rawAmount
                : num.tryParse(rawAmount.toString()) ?? 0;
            final currentStatus = _orderStatuses[orderId] ??
                (order['orderStatus'] ?? "Tiếp nhận đơn");

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(
                              orderId: orderId),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("Bàn: $tableName",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text("Mã đơn hàng: #$orderId",
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black)),
                          const SizedBox(height: 6),
                          Text(
                              "Ngày đặt: ${formatDate(orderDate)}",
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            "Tổng tiền: ${formatCurrency(totalAmount)}",
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "Tiếp nhận đơn",
                          child: Text("Tiếp nhận đơn")),
                      DropdownMenuItem(
                          value: "Đang chuẩn bị",
                          child: Text("Đang chuẩn bị")),
                      DropdownMenuItem(
                          value: "Hoàn thành",
                          child: Text("Hoàn thành")),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      final ok = await _orderService
                          .updateOrderStatus(orderId, value);
                      if (ok) {
                        // ✅ Nếu chọn "Hoàn thành", gọi lại API để lọc danh sách
                        if (value == "Hoàn thành") {
                          await _reloadOrders();
                        } else {
                          setState(() {
                            _orderStatuses[orderId] = value;
                          });
                        }

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                                "Cập nhật trạng thái đơn #$orderId → $value"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text("Cập nhật thất bại"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
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
