class MenuOrderVariant {
  final int foodSizeId;
  final String foodSizeName;
  final double price;

  MenuOrderVariant({
    required this.foodSizeId,
    required this.foodSizeName,
    required this.price,
  });

  factory MenuOrderVariant.fromJson(Map<String, dynamic> json) {
    return MenuOrderVariant(
      foodSizeId: json['foodSizeId'],
      foodSizeName: json['foodSizeName'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

class MenuOrderModel {
  final int menuId;
  final String menuName;
  final List<String> images;
  final List<MenuOrderVariant> variants;

  MenuOrderModel({
    required this.menuId,
    required this.menuName,
    required this.images,
    required this.variants,
  });

  factory MenuOrderModel.fromJson(Map<String, dynamic> json) {
    return MenuOrderModel(
      menuId: json['menuId'],
      menuName: json['menuName'],
      images: List<String>.from(json['images'] ?? []),
      variants: (json['variants'] as List<dynamic>)
          .map((v) => MenuOrderVariant.fromJson(v))
          .toList(),
    );
  }
}
