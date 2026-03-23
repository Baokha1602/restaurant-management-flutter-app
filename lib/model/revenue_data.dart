class RevenueData {
  final double totalAmount;
  final DateTime date;

  RevenueData({
    required this.totalAmount,
    required this.date,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      totalAmount: (json['totalAmount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}
