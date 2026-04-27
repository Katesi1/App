import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int role;
  final bool isActive;
  final int? gender;
  final String? dateOfBirth;
  final String? ownerId;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isActive = true,
    this.gender,
    this.dateOfBirth,
    this.ownerId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'],
        role: json['role'] ?? 3,
        isActive: json['isActive'] ?? true,
        gender: json['gender'],
        dateOfBirth: json['dateOfBirth'],
        ownerId: json['ownerId'],
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
        if (ownerId != null) 'ownerId': ownerId,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String str) =>
      UserModel.fromJson(jsonDecode(str));

  // 0=ADMIN, 1=OWNER, 2=SALE, 3=CUSTOMER
  bool get isAdmin => role == 0;
  bool get isOwner => role == 1;
  bool get isSale => role == 2;
  bool get isCustomer => role == 3;

  /// ADMIN + OWNER + SALE = quản lý (xem dashboard, CRUD phòng/booking)
  bool get isManagement => isAdmin || isOwner || isSale;

  /// Có quyền chỉnh sửa (sửa phòng, booking, lịch)
  bool get canEdit => isAdmin || isOwner || isSale;

  /// Có quyền tạo/xóa property (SALE không được)
  bool get canManageProperty => isAdmin || isOwner;

  /// SALE đã được gán cho owner chưa
  bool get hasOwner => ownerId != null;

  /// ID owner hiệu lực: OWNER → mình, SALE → ownerId
  String? get effectiveOwnerId =>
      isOwner ? id : (isSale ? ownerId : null);
}
