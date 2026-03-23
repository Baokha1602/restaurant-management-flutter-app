class MenuCategory {
  final int menuCategoryId;
  final String menuCategoryName;

  MenuCategory({
    required this.menuCategoryId,
    required this.menuCategoryName,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      menuCategoryId: json['menuCategoryId'] ?? 0,
      menuCategoryName: json['menuCategoryName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'menuCategoryId': menuCategoryId,
    'menuCategoryName': menuCategoryName,
  };
}
