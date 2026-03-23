class StatisticsSummary {
  final int numberOfCustomers;
  final int numberOfEmployees;
  final double totalOfOrderInDay;

  StatisticsSummary({
    required this.numberOfCustomers,
    required this.numberOfEmployees,
    required this.totalOfOrderInDay,
  });

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      numberOfCustomers: json['numberOfCustomser'] as int,
      numberOfEmployees: json['numberOfEmployee'] as int,
      totalOfOrderInDay: (json['totalOfOrderInDay'] as num).toDouble(),
    );
  }
}
