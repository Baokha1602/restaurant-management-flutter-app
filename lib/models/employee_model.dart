class Employee {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? urlImage;
  final String? dateOfBirth;
  final int gender;

  Employee({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.urlImage,
    this.dateOfBirth,
    required this.gender,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      urlImage: json['urlImage'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'urlImage': urlImage,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    };
  }
}
