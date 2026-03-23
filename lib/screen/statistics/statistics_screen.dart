import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/revenue_data.dart';
import '../../model/statistics_summary.dart';
import '../../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  Future<StatisticsSummary>? _summaryFuture;
  Future<List<RevenueData>>? _revenueFuture;
  final Color primaryColor = const Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _summaryFuture = _statisticsService.fetchSummaryData();
    _revenueFuture = _statisticsService.fetchAllRevenue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê Doanh thu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: Future.wait([_summaryFuture!, _revenueFuture!]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Không có dữ liệu thống kê.'));
          }

          final StatisticsSummary summary = snapshot.data![0];
          final List<RevenueData> revenues = snapshot.data![1];

          return _buildDashboard(summary, revenues);
        },
      ),
    );
  }

  Widget _buildDashboard(StatisticsSummary summary, List<RevenueData> revenues) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(summary, currencyFormatter),
          const SizedBox(height: 24),

          // Monthly Revenue Chart
          _buildChartCard(
            'Doanh thu theo Tháng (Năm nay)',
            _buildMonthlyBarChart(revenues, currencyFormatter),
          ),
          const SizedBox(height: 24),

          // Last 30 Days Revenue Chart
          _buildChartCard(
            'Doanh thu 30 ngày qua',
            _buildDailyLineChart(revenues, currencyFormatter),
          ),
           const SizedBox(height: 24),

          // Yearly Revenue Chart
          _buildChartCard(
            'Doanh thu theo Năm',
            _buildYearlyBarChart(revenues, currencyFormatter),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(StatisticsSummary summary, NumberFormat formatter) {
    return Column(
      children: [
         _buildSummaryCard('Doanh thu Hôm nay', formatter.format(summary.totalOfOrderInDay), Icons.monetization_on, Colors.green),
         const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Tổng Khách hàng', summary.numberOfCustomers.toString(), Icons.people, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Tổng Nhân viên', summary.numberOfEmployees.toString(), Icons.badge, Colors.orange)),
          ],
        ),
      ],
    );
  }

   Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                ),
                const SizedBox(width: 8),
                 CircleAvatar(
                   radius: 16,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, size: 20, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }


  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 250, child: chart),
             const SizedBox(height: 8),
          ],
        ),
    );
  }

  // Chart 1: Monthly Revenue
  Widget _buildMonthlyBarChart(List<RevenueData> revenues, NumberFormat formatter) {
    Map<int, double> monthlyData = {};
    int currentYear = DateTime.now().year;

    for (var r in revenues) {
      if (r.date.year == currentYear) {
        monthlyData.update(r.date.month, (value) => value + r.totalAmount, ifAbsent: () => r.totalAmount);
      }
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= 12; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: monthlyData[i] ?? 0, color: primaryColor, width: 22, borderRadius: BorderRadius.zero)],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 600, // Provide ample width for 12 months
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween, 
            barGroups: barGroups,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text('T${value.toInt()}', style: const TextStyle(fontSize: 12)),
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80, // Make space for labels
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(formatter.format(value).replaceAll('₫', ''), style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5000000),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    'Tháng ${group.x.toInt()}\n', 
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatter.format(rod.toY),
                        style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Chart 2: Daily Revenue (Last 30 days)
  Widget _buildDailyLineChart(List<RevenueData> revenues, NumberFormat formatter) {
     Map<int, double> dailyData = {};
    DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    for (var r in revenues) {
      if (r.date.isAfter(thirtyDaysAgo)) {
        dailyData.update(r.date.day, (value) => value + r.totalAmount, ifAbsent: () => r.totalAmount);
      }
    }

    List<FlSpot> spots = [];
    for (int i = 1; i <= DateTime.now().day; i++) {
      spots.add(FlSpot(i.toDouble(), dailyData[i] ?? 0));
    }

    return LineChart(
       LineChartData(
         minY: 0,
         titlesData: FlTitlesData(
           bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5, getTitlesWidget: (value, meta) => Text(value.toInt().toString()))),
            leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80, // Make space for labels
               getTitlesWidget: (value, meta) {
                 if (value == 0) return const Text('');
                return Text(formatter.format(value).replaceAll('₫', ''), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
         ),
         gridData: const FlGridData(show: true, drawVerticalLine: false),
         borderData: FlBorderData(show: false),
         lineBarsData: [
           LineChartBarData(
             spots: spots,
             isCurved: true,
             color: primaryColor,
             barWidth: 4,
             belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.3)),
           )
         ]
       )
    );
  }

  // Chart 3: Yearly Revenue
  Widget _buildYearlyBarChart(List<RevenueData> revenues, NumberFormat formatter) {
    Map<int, double> yearlyData = {};

    for (var r in revenues) {
        yearlyData.update(r.date.year, (value) => value + r.totalAmount, ifAbsent: () => r.totalAmount);
    }

    List<BarChartGroupData> barGroups = [];
    yearlyData.forEach((year, total) {
       barGroups.add(
        BarChartGroupData(
          x: year,
          barRods: [BarChartRodData(toY: total, color: primaryColor, width: 30, borderRadius: BorderRadius.zero)],
        ),
      );
    });


    return BarChart(
       BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
              reservedSize: 30,
            ),
          ),
           leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80, // Make space for labels
               getTitlesWidget: (value, meta) {
                 if (value == 0) return const Text('');
                return Text(formatter.format(value).replaceAll('₫', ''), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50000000),
        borderData: FlBorderData(show: false),
         barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Năm ${group.x.toInt()}\n', 
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: formatter.format(rod.toY),
                    style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
