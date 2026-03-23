import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import '../model/revenue_data.dart';
import '../model/statistics_summary.dart';
import '../utils/get_headers.dart';

class StatisticsService {
  Future<StatisticsSummary> fetchSummaryData() async {
    final response = await http.get(
      Uri.parse('${Config_URL.baseApiUrl}/RevenueApi/GetNumberOfUserandRevenueOfDay'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return StatisticsSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Lỗi khi tải dữ liệu tóm tắt');
    }
  }

  Future<List<RevenueData>> fetchAllRevenue() async {
    final response = await http.get(
      Uri.parse('${Config_URL.baseApiUrl}/RevenueApi'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RevenueData.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải dữ liệu doanh thu');
    }
  }
}
