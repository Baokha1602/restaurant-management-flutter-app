import 'dart:convert';

// Phương thức để parse JSON thành danh sách CustomerRank
List<CustomerRank> customerRankFromJson(String str) => List<CustomerRank>.from(json.decode(str).map((x) => CustomerRank.fromJson(x)));

// Phương thức để chuyển danh sách CustomerRank thành JSON
String customerRankToJson(List<CustomerRank> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CustomerRank {
  int? rankId;
  String rankName;
  int rankPoint;
  int? rankDiscount;
  int? customerCount;

  CustomerRank({
    this.rankId,
    required this.rankName,
    required this.rankPoint,
    this.rankDiscount,
  });

  factory CustomerRank.fromJson(Map<String, dynamic> json) => CustomerRank(
    rankId: json["rankId"],
    rankName: json["rankName"],
    rankPoint: json["rankPoint"],
    rankDiscount: json["rankDiscount"],
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "rankName": rankName,
      "rankPoint": rankPoint,
      "rankDiscount": rankDiscount,
    };
    if (rankId != null) { // CHỈ THÊM rankId VÀO JSON NẾU NÓ KHÔNG PHẢI LÀ NULL
      data["rankId"] = rankId;
    }
    return data;
  }
}