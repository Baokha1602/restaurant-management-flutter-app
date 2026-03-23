import 'package:flutter/material.dart';
import '../../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _details = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final result = await _orderService.getOrderDetails(widget.orderId);
    setState(() {
      _details = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn #${widget.orderId}"),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _details.length,
        itemBuilder: (context, index) {
          final item = _details[index];
          return Card(
            color: Colors.white,
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: item['urlImage'] != null
                  ? Image.network(item['urlImage'], width: 60, height: 60, fit: BoxFit.cover)
                  : const Icon(Icons.fastfood, size: 40, color: Colors.orange),
              title: Text(item['foodName'] ?? ''),
              subtitle: Text("Số lượng: ${item['quantity']}"),
            ),
          );
        },
      ),
    );
  }
}
