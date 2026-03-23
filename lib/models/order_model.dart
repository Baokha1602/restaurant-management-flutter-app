import '../config/config_url.dart';

class OrderModel {
  final int orderId;
  final double totalAmount;
  final String orderStatus;
  final DateTime orderDate;
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime? paymentDate;
  final int tableId;
  final String customerId;

  OrderModel({
    required this.orderId,
    required this.totalAmount,
    required this.orderStatus,
    required this.orderDate,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentDate,
    required this.tableId,
    required this.customerId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'],
      totalAmount: (json['totalAmount'] as num).toDouble(), // Chuyển đổi sang double
      orderStatus: json['orderStatus'],
      orderDate: DateTime.parse(json['orderDate']),
      paymentStatus: json['paymentStatus'],
      paymentMethod: json['paymentMethod'],
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
      tableId: json['tableId'],
      customerId: json['customerId'],
    );
  }
}

class OrderDetailModel {
  final String foodName;
  final int quantity;
  final String? urlImage;

  OrderDetailModel({
    required this.foodName,
    required this.quantity,
    this.urlImage,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      foodName: json['foodName'],
      quantity: json['quantity'],
      urlImage: json['urlImage'] != null ? "${Config_URL.baseUrl}/${json['urlImage']}" : null,
    );
  }
}