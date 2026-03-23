class MenuModel {
  final int menuId;
  final String menuName;
  final String menuCategoryName;
  final String? detail;

  // 👇 Thêm hai trường mới để khớp backend
  final String? mainImageUrl;       // ảnh chính hiển thị ở danh sách
  final List<String>? imageUrls;    // danh sách ảnh (xem chi tiết)

  MenuModel({
    required this.menuId,
    required this.menuName,
    required this.menuCategoryName,
    this.detail,
    this.mainImageUrl,
    this.imageUrls,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) => MenuModel(
    menuId: json['menuId'],
    menuName: json['menuName'],
    menuCategoryName: json['menuCategoryName'],
    detail: json['detail'],
    mainImageUrl: json['mainImageUrl'],
    imageUrls: (json['imageUrls'] as List?)
        ?.map((e) => e.toString())
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'menuId': menuId,
    'menuName': menuName,
    'menuCategoryName': menuCategoryName,
    'detail': detail,
    'mainImageUrl': mainImageUrl,
    'imageUrls': imageUrls,
  };
}
