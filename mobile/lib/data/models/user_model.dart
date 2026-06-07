import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Model chính cho user. Tất cả 3 endpoint auth (login/register/google) +
/// /auth/profile + /staff/* đều dùng cùng shape — xem API.md Section 5.3.
///
/// Generate `.g.dart`:
///   dart run build_runner build --delete-conflicting-outputs
@JsonSerializable(explicitToJson: true)
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;
  @JsonKey(defaultValue: false)
  final bool emailVerified;
  @JsonKey(defaultValue: 3)
  final int role;
  @JsonKey(defaultValue: true)
  final bool isActive;
  final int? gender;
  final String? dateOfBirth;
  final String? ownerId;
  final String? saleMembershipStatus;

  // ── KYC + Subscription (BE trả từ /auth/profile) ──
  @JsonKey(defaultValue: 'none')
  final String kycStatus; // none | pending | approved | rejected
  final String? kycSubmissionId;
  @JsonKey(defaultValue: 'none')
  final String
      subscriptionStatus; // none | trial | active | past_due | cancelled
  final String? subscriptionPlanId; // starter | professional | enterprise
  final String? subscriptionCycle; // monthly | yearly
  final DateTime? trialEndsAt;
  final DateTime? nextChargeAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final String? pendingPlanId;
  final String? pendingCycle;
  final DateTime? pendingEffectiveAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    this.emailVerified = false,
    required this.role,
    this.isActive = true,
    this.gender,
    this.dateOfBirth,
    this.ownerId,
    this.saleMembershipStatus,
    this.kycStatus = 'none',
    this.kycSubmissionId,
    this.subscriptionStatus = 'none',
    this.subscriptionPlanId,
    this.subscriptionCycle,
    this.trialEndsAt,
    this.nextChargeAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.pendingPlanId,
    this.pendingCycle,
    this.pendingEffectiveAt,
  });

  /// Defensive fromJson — bao quanh `_$UserModelFromJson` để xử lý các field
  /// required-but-null từ BE cũ (id/name/phone đôi khi missing trong response
  /// fallback). KHÔNG sửa generated file.
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson({
        ...json,
        'id': json['id'] ?? '',
        'name': json['name'] ?? '',
        'phone': json['phone'] ?? '',
      });

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String str) =>
      UserModel.fromJson(jsonDecode(str) as Map<String, dynamic>);

  // ── Role helpers (0=ADMIN, 1=OWNER, 2=SALE, 3=CUSTOMER) ──
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

  /// Trạng thái membership của SALE dưới owner:
  /// invited | active | suspended | unassigned.
  /// Fallback từ ownerId để tương thích backend cũ chưa trả field này.
  String get saleMembershipState {
    if (!isSale) return 'active';
    final status = saleMembershipStatus?.trim();
    if (status != null && status.isNotEmpty) {
      return status;
    }
    return hasOwner ? 'active' : 'unassigned';
  }

  bool get isSaleMembershipActive => !isSale || saleMembershipState == 'active';
  bool get isSaleMembershipInvited => saleMembershipState == 'invited';
  bool get isSaleMembershipSuspended => saleMembershipState == 'suspended';
  bool get isSaleMembershipUnassigned => saleMembershipState == 'unassigned';

  /// ID owner hiệu lực: OWNER → mình, SALE → ownerId
  String? get effectiveOwnerId => isOwner ? id : (isSale ? ownerId : null);

  // ── KYC helpers ──
  bool get isKycApproved => kycStatus == 'approved';
  bool get isKycPending => kycStatus == 'pending';
  bool get isKycRejected => kycStatus == 'rejected';
  bool get isKycNone => kycStatus == 'none';

  /// OWNER chưa hoàn thành KYC → bị chặn tạo/sửa property.
  /// ADMIN, SALE không yêu cầu KYC. CUSTOMER không quan tâm.
  bool get needsKyc => isOwner && !isKycApproved;

  /// Quyền mutate trong management:
  /// - ADMIN/OWNER luôn được
  /// - SALE chỉ khi membership active
  bool get canMutateManagementData =>
      isAdmin || isOwner || (isSale && isSaleMembershipActive);

  // ── Subscription helpers ──
  bool get isInTrial => subscriptionStatus == 'trial';
  bool get isSubscriptionActive => subscriptionStatus == 'active';
  bool get isSubscriptionPastDue => subscriptionStatus == 'past_due';
  bool get isSubscriptionCancelled => subscriptionStatus == 'cancelled';
  bool get isSubscriptionFrozen => subscriptionStatus == 'frozen';
  bool get isSubscriptionExpired => subscriptionStatus == 'expired';

  /// Số ngày còn lại của trial (null nếu không trong trial). Làm tròn xuống.
  int? get trialDaysLeft {
    if (!isInTrial || trialEndsAt == null) return null;
    final diff = trialEndsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Tên gói hiển thị (Mini, Starter, ...).
  String get subscriptionPlanLabel => planLabelFor(subscriptionPlanId);

  /// Label gói từ planId — dùng cho pending downgrade banner.
  static String planLabelFor(String? planId) {
    if (planId == null || planId.isEmpty) return 'Chưa có gói';
    return switch (planId) {
      'rooms_1' || 'mini' => 'Mini',
      'rooms_5' || 'starter' => 'Starter',
      'rooms_10' || 'standard' => 'Standard',
      'rooms_20' || 'pro' || 'professional' => 'Pro',
      'rooms_50' || 'business' => 'Business',
      'rooms_unlimited' || 'enterprise' => 'Enterprise',
      'starter_test' => 'Starter Test',
      _ => planId,
    };
  }

  String get pendingPlanLabel => planLabelFor(pendingPlanId);

  bool get hasPendingDowngrade =>
      pendingPlanId != null && pendingPlanId!.isNotEmpty;

  /// Số ngày còn lại của kỳ hiện tại (từ `currentPeriodEnd`). Null nếu không có.
  int? get periodDaysLeft {
    if (currentPeriodEnd == null) return null;
    final diff = currentPeriodEnd!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Subtitle cho menu/card Mua gói trên profile & quản lý.
  String get subscriptionMenuSubtitle {
    if (isInTrial) {
      final days = trialDaysLeft ?? 0;
      return 'Trial $subscriptionPlanLabel · còn $days ngày';
    }
    if (isSubscriptionActive) {
      return 'Đang dùng $subscriptionPlanLabel';
    }
    if (isSubscriptionPastDue) {
      return 'Quá hạn thanh toán · $subscriptionPlanLabel';
    }
    if (isSubscriptionCancelled) {
      return 'Gói đã huỷ · Mua lại để tiếp tục';
    }
    return 'Chọn gói phù hợp với số phòng';
  }

  /// Badge trailing trên card quản lý.
  String get subscriptionTrailingLabel {
    if (isInTrial) return 'Trial';
    if (isSubscriptionActive) return subscriptionPlanLabel;
    if (isSubscriptionPastDue) return 'Quá hạn';
    if (isSubscriptionCancelled) return 'Đã huỷ';
    return 'Chưa có';
  }

  /// Màn đầu tiên khi vào luồng mua/quản lý gói — chi tiết trước, chọn gói sau.
  static const subscriptionEntryRoute = '/verify/subscription-detail';

  /// Route màn hình quản lý/mua gói (luôn chi tiết gói đăng ký).
  String get subscriptionManageRoute => subscriptionEntryRoute;

  /// Đã từng có subscription (trial/active/past_due/cancelled).
  bool get hasEverPurchasedSubscription => subscriptionStatus != 'none';

  /// Nút mua lần đầu vs nâng cấp gói hiện có.
  String get subscriptionPlanActionLabel =>
      hasEverPurchasedSubscription ? 'Nâng cấp gói' : 'Mua gói';

  /// Route chọn gói — upgrade mode khi đã từng mua.
  String get subscriptionPlanPickerRoute => hasEverPurchasedSubscription
      ? '/verify/select-plan?mode=upgrade'
      : '/verify/select-plan';

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    bool? emailVerified,
    int? role,
    bool? isActive,
    int? gender,
    String? dateOfBirth,
    String? ownerId,
    String? saleMembershipStatus,
    String? kycStatus,
    String? kycSubmissionId,
    String? subscriptionStatus,
    String? subscriptionPlanId,
    String? subscriptionCycle,
    DateTime? trialEndsAt,
    DateTime? nextChargeAt,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    String? pendingPlanId,
    String? pendingCycle,
    DateTime? pendingEffectiveAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        emailVerified: emailVerified ?? this.emailVerified,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        ownerId: ownerId ?? this.ownerId,
        saleMembershipStatus: saleMembershipStatus ?? this.saleMembershipStatus,
        kycStatus: kycStatus ?? this.kycStatus,
        kycSubmissionId: kycSubmissionId ?? this.kycSubmissionId,
        subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
        subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
        subscriptionCycle: subscriptionCycle ?? this.subscriptionCycle,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        nextChargeAt: nextChargeAt ?? this.nextChargeAt,
        currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
        pendingPlanId: pendingPlanId ?? this.pendingPlanId,
        pendingCycle: pendingCycle ?? this.pendingCycle,
        pendingEffectiveAt: pendingEffectiveAt ?? this.pendingEffectiveAt,
      );
}
