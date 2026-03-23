import 'package:flutter/foundation.dart';

class DiscountModel {
  final String discountId;
  final String discountName;
  final String discountCategory;
  final double discountPrice;
  final String dateStart;
  final String dateEnd;
  final bool discountStatus;
  final int requiredPoints; // 👈 Thêm trường điểm cần đổi

  const DiscountModel({
    required this.discountId,
    required this.discountName,
    required this.discountCategory,
    required this.discountPrice,
    required this.dateStart,
    required this.dateEnd,
    required this.discountStatus,
    required this.requiredPoints,
  });

  /// Parse dữ liệu từ API (camelCase)
  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    debugPrint("📥 Nhận từ API: $json");

    return DiscountModel(
      discountId: json['discountId'] ?? '',
      discountName: json['discountName'] ?? '',
      discountCategory: json['discountCategory'] ?? '',
      discountPrice: (json['discountPrice'] ?? 0).toDouble(),
      dateStart: json['dateStart'] ?? '',
      dateEnd: json['dateEnd'] ?? '',
      discountStatus: json['discountStatus'] ?? false,
      requiredPoints: json['requiredPoints'] ?? 0, // 👈 Map thêm trường mới
    );
  }

  /// Convert sang JSON để gửi lên server (camelCase)
  Map<String, dynamic> toJson() {
    final data = {
      "discountId": discountId,
      "discountName": discountName,
      "discountCategory": discountCategory,
      "discountPrice": discountPrice,
      "dateStart": dateStart,
      "dateEnd": dateEnd,
      "discountStatus": discountStatus,
      "requiredPoints": requiredPoints, // 👈 Gửi lên server khi tạo/sửa
    };
    debugPrint("🧾 toJson() => $data");
    return data;
  }

  /// Dễ dàng clone hoặc chỉnh sửa model
  DiscountModel copyWith({
    String? discountId,
    String? discountName,
    String? discountCategory,
    double? discountPrice,
    String? dateStart,
    String? dateEnd,
    bool? discountStatus,
    int? requiredPoints,
  }) {
    return DiscountModel(
      discountId: discountId ?? this.discountId,
      discountName: discountName ?? this.discountName,
      discountCategory: discountCategory ?? this.discountCategory,
      discountPrice: discountPrice ?? this.discountPrice,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      discountStatus: discountStatus ?? this.discountStatus,
      requiredPoints: requiredPoints ?? this.requiredPoints,
    );
  }
}
