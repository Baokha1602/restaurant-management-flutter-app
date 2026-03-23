class DiscountCustomerModel {
  final String discountId;
  final String customerId;
  final bool isUsed;

  DiscountCustomerModel({
    required this.discountId,
    required this.customerId,
    this.isUsed = false,
  });

  Map<String, dynamic> toJson() => {
    "discountId": discountId,
    "customerId": customerId,
    "isUsed": isUsed,
  };

  factory DiscountCustomerModel.fromJson(Map<String, dynamic> json) {
    return DiscountCustomerModel(
      discountId: json["discountId"] ?? "",
      customerId: json["customerId"] ?? "",
      isUsed: json["isUsed"] ?? false,
    );
  }
}
