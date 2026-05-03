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

  // ── KYC + Subscription (backend trả từ /auth/profile sau Đợt 2) ──
  final String kycStatus; // none | pending | approved | rejected
  final String? kycSubmissionId;
  final String subscriptionStatus; // none | trial | active | past_due | cancelled
  final String? subscriptionPlanId; // starter | professional | enterprise
  final String? subscriptionCycle; // monthly | yearly
  final DateTime? trialEndsAt;
  final DateTime? nextChargeAt;

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
    this.kycStatus = 'none',
    this.kycSubmissionId,
    this.subscriptionStatus = 'none',
    this.subscriptionPlanId,
    this.subscriptionCycle,
    this.trialEndsAt,
    this.nextChargeAt,
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
        kycStatus: json['kycStatus'] ?? 'none',
        kycSubmissionId: json['kycSubmissionId'],
        subscriptionStatus: json['subscriptionStatus'] ?? 'none',
        subscriptionPlanId: json['subscriptionPlanId'],
        subscriptionCycle: json['subscriptionCycle'],
        trialEndsAt: _parseDate(json['trialEndsAt']),
        nextChargeAt: _parseDate(json['nextChargeAt']),
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

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
        'kycStatus': kycStatus,
        if (kycSubmissionId != null) 'kycSubmissionId': kycSubmissionId,
        'subscriptionStatus': subscriptionStatus,
        if (subscriptionPlanId != null) 'subscriptionPlanId': subscriptionPlanId,
        if (subscriptionCycle != null) 'subscriptionCycle': subscriptionCycle,
        if (trialEndsAt != null) 'trialEndsAt': trialEndsAt!.toIso8601String(),
        if (nextChargeAt != null) 'nextChargeAt': nextChargeAt!.toIso8601String(),
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

  // ── KYC helpers ──
  bool get isKycApproved => kycStatus == 'approved';
  bool get isKycPending => kycStatus == 'pending';
  bool get isKycRejected => kycStatus == 'rejected';
  bool get isKycNone => kycStatus == 'none';

  /// OWNER chưa hoàn thành KYC → bị chặn tạo/sửa property.
  /// ADMIN, SALE không yêu cầu KYC. CUSTOMER không quan tâm.
  bool get needsKyc => isOwner && !isKycApproved;

  // ── Subscription helpers ──
  bool get isInTrial => subscriptionStatus == 'trial';
  bool get isSubscriptionActive => subscriptionStatus == 'active';
  bool get isSubscriptionPastDue => subscriptionStatus == 'past_due';
  bool get isSubscriptionCancelled => subscriptionStatus == 'cancelled';

  /// Số ngày còn lại của trial (null nếu không trong trial). Làm tròn xuống.
  int? get trialDaysLeft {
    if (!isInTrial || trialEndsAt == null) return null;
    final diff = trialEndsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    int? role,
    bool? isActive,
    int? gender,
    String? dateOfBirth,
    String? ownerId,
    String? kycStatus,
    String? kycSubmissionId,
    String? subscriptionStatus,
    String? subscriptionPlanId,
    String? subscriptionCycle,
    DateTime? trialEndsAt,
    DateTime? nextChargeAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        ownerId: ownerId ?? this.ownerId,
        kycStatus: kycStatus ?? this.kycStatus,
        kycSubmissionId: kycSubmissionId ?? this.kycSubmissionId,
        subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
        subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
        subscriptionCycle: subscriptionCycle ?? this.subscriptionCycle,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        nextChargeAt: nextChargeAt ?? this.nextChargeAt,
      );
}
