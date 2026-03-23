import '../config/config_url.dart';

class CustomerDTO {
  String? customerId;
  String name;
  String email;
  String phoneNumber;
  int gender;
  String? dateOfBirth;
  String? urlImage;
  String? rankName;
  int? rankId;
  int? point;
  bool isLocked;

  CustomerDTO({
    this.customerId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    this.dateOfBirth,
    this.urlImage,
    this.rankName,
    this.rankId,
    this.point,
    this.isLocked = false,
  });

  //  Factory tạo đối tượng từ JSON
  factory CustomerDTO.fromJson(Map<String, dynamic> json) {
    return CustomerDTO(
      customerId: json['customerId'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? 0,
      dateOfBirth: json['dateOfBirth'],
      urlImage: json['urlImage'],
      rankName: json['rankName'],
      rankId: json['rankId'],
      point: json['point'],
      isLocked: json['isLocked'] ?? false,
    );
  }

  //  Trả về JSON khi gửi lên server
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'urlImage': urlImage,
      'rankName': rankName,
      'rankId': rankId,
      'point': point,
    };
  }

  //  Getter tự động ghép base URL khi hiển thị ảnh
  String get fullImageUrl {
    final baseUrl = Config_URL.baseUrl;

    if (urlImage == null || urlImage!.isEmpty) {
      // fallback khi không có ảnh
      return "$baseUrl/images/default_user.png";
    }

    // Nếu backend đã trả sẵn URL đầy đủ thì giữ nguyên
    if (urlImage!.startsWith('http')) return urlImage!;

    // Ngược lại, ghép domain vào
    return "$baseUrl${urlImage!}";
  }
// String get fullImageUrl {
//   final baseUrl = Config_URL.baseUrl;
//
//   if (urlImage == null ||
//       urlImage!.isEmpty ||
//       urlImage!.contains('GuestUser')) {
//     // fallback ảnh mặc định (GuestUser)
//     return "$baseUrl/Images/GuestUser/GuestUser.jpg";
//   }
//
//   if (urlImage!.startsWith('http')) return urlImage!;
//   return urlImage!.startsWith('/')
//       ? "$baseUrl${urlImage!}"
//       : "$baseUrl/${urlImage!}";
// }

}