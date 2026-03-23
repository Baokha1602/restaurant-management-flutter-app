class FoodSize {
  final int foodSizeId;
  final String menuName;
  final String foodName;
  final double price;
  final int sortOrder;

  FoodSize({
    required this.foodSizeId,
    required this.menuName,
    required this.foodName,
    required this.price,
    required this.sortOrder,
  });

  factory FoodSize.fromJson(Map<String, dynamic> json) {
    return FoodSize(
      foodSizeId: json['foodSizeId'] ?? 0,
      menuName: json['menuName'] ?? '',
      foodName: json['foodName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'foodSizeId': foodSizeId,
    'menuName': menuName,
    'foodName': foodName,
    'price': price,
    'sortOrder': sortOrder,
  };
}
