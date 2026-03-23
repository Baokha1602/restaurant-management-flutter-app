class Inventory {
  final int inventoryId;
  final int foodSizeId;
  final String menuName;
  final String foodSizeName;
  final String unit;
  int quantity; // có thể chỉnh trực tiếp trong UI

  Inventory({
    required this.inventoryId,
    required this.foodSizeId,
    required this.menuName,
    required this.foodSizeName,
    required this.unit,
    required this.quantity,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      inventoryId: json['inventoryId'] ?? 0,
      foodSizeId: json['foodSizeId'] ?? 0,
      menuName: json['menuName'] ?? '',
      foodSizeName: json['foodSizeName'] ?? '',
      unit: json['unit'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "inventoryId": inventoryId,
    "foodSizeId": foodSizeId,
    "unit": unit,
    "quantity": quantity,
  };
}
