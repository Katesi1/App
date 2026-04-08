import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool isActive;
  final String? gender;
  final String? dateOfBirth;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isActive = true,
    this.gender,
    this.dateOfBirth,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'],
        role: json['role'] ?? 'CUSTOMER',
        isActive: json['isActive'] ?? true,
        gender: json['gender'],
        dateOfBirth: json['dateOfBirth'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'isActive': isActive,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String str) =>
      UserModel.fromJson(jsonDecode(str));

  bool get isAdmin => role == 'ADMIN';
  bool get isStaff => role == 'STAFF';
  bool get isCustomer => role == 'CUSTOMER';

  /// ADMIN + STAFF = quản lý (xem dashboard, CRUD phòng/booking)
  bool get isManagement => isAdmin || isStaff;

  /// Có quyền chỉnh sửa (tạo/sửa phòng, homestay)
  bool get canEdit => isAdmin || isStaff;
}
