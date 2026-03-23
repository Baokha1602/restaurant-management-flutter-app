import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/payment_service.dart';

class ConfirmOrderPayByCash extends StatefulWidget {
  const ConfirmOrderPayByCash({super.key});

  @override
  State<ConfirmOrderPayByCash> createState() => _ConfirmOrderPayByCashState();
}

class _ConfirmOrderPayByCashState extends State<ConfirmOrderPayByCash> {
  final PaymentService _paymentService = PaymentService();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final data = await _paymentService.getOrdersPayByCash();
    setState(() {
      _orders = data;
      _isLoading = false;
    });
  }

  String formatCurrency(num value) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

  Future<void> _confirmPayment(Map<String, dynamic> order) async {
    final orderId = order['orderId'];
    final total = order['totalAmount'];
    final tableName = order['tableName'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text("Xác nhận thanh toán"),
        content: Text(
          "Bạn có chắc chắn đơn hàng #$orderId (bàn $tableName) đã trả tiền mặt với số tiền ${formatCurrency(total)} không?",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Không", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Có", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _paymentService.confirmOrderPayByCash(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Đã xác nhận.'),
          backgroundColor: result['isSuccess'] == true
              ? Colors.green
              : Colors.redAccent,
        ),
      );

      // Tải lại danh sách
      if (result['isSuccess'] == true) {
        await _fetchOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        title: const Text(
          "Xác nhận thanh toán tiền mặt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrders,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _orders.isEmpty
          ? const Center(
        child: Text(
          "Không có đơn hàng thanh toán tiền mặt.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchOrders,
        color: Colors.orange,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Đơn hàng #${order['orderId']}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("Bàn: ${order['tableName']}",
                      style: const TextStyle(fontSize: 14)),
                  Text(
                    "Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order['orderDate']))}",
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tổng tiền: ${formatCurrency(order['totalAmount'])}",
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _confirmPayment(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        "Xác nhận trả tiền",
                        style: TextStyle(color: Colors.white),
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
