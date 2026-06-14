import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Shared user shape used by all auth endpoints (login/register/google),
/// /auth/profile and /staff/*. Regenerate with:
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

  // KYC + Subscription state mirrored from GET /auth/profile.
  @JsonKey(defaultValue: 'none')
  final String kycStatus; // none | pending | approved | rejected
  final String? kycSubmissionId;
  @JsonKey(defaultValue: 'none')
  final String
      subscriptionStatus; // none | trial | active | past_due | cancelled
  final String? subscriptionPlanId; // rooms_1 | rooms_5 | ... | enterprise
  final String? subscriptionCycle; // monthly | yearly
  final String? subscriptionProvider; // bank_transfer | null (legacy: vnpay)
  final DateTime?
      subscriptionExpiresAt; // subscription/trial expiry from backend
  final DateTime? trialEndsAt;
  final DateTime? nextChargeAt;

  // Billing period + scheduled downgrade (BE §10.2.5).
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd; // hết hạn kỳ hiện tại
  final String? pendingPlanId; // downgrade đã đặt lịch
  final String? pendingCycle;
  final DateTime? pendingEffectiveAt; // ngày downgrade có hiệu lực

  // Account deletion grace period (v1.14 / NĐ 13).
  // null = normal, ISO = pending deletion scheduled at this date.
  final DateTime? deletionScheduledAt;

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
    this.subscriptionProvider,
    this.subscriptionExpiresAt,
    this.trialEndsAt,
    this.nextChargeAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.pendingPlanId,
    this.pendingCycle,
    this.pendingEffectiveAt,
    this.deletionScheduledAt,
  });

  /// Có lịch hạ gói chờ áp dụng từ kỳ sau.
  bool get hasPendingDowngrade => pendingPlanId != null;

  /// Tài khoản đang trong grace period 30 ngày chờ xoá (NĐ 13 / GDPR).
  bool get isPendingDeletion => deletionScheduledAt != null;

  /// Số ngày còn lại trước khi tài khoản bị xoá, hoặc null nếu không pending.
  int? get deletionDaysLeft {
    if (deletionScheduledAt == null) return null;
    final diff = deletionScheduledAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Defensive wrapper around `_$UserModelFromJson` — older backends may omit
  /// id/name/phone on some responses. The generated file stays untouched.
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

  // Role helpers (0=ADMIN, 1=OWNER, 2=SALE).
  bool get isAdmin => role == 0;
  bool get isOwner => role == 1;
  bool get isSale => role == 2;

  /// All recognised roles can manage data — kept as a helper for call sites
  /// that still ask the question, even though the app no longer has a
  /// non-management role.
  bool get isManagement => isAdmin || isOwner || isSale;

  /// Can edit rooms, bookings, calendar.
  bool get canEdit => isAdmin || isOwner || isSale;

  /// Can create/delete a property (SALE cannot).
  bool get canManageProperty => isAdmin || isOwner;

  /// SALE is assigned to an OWNER.
  bool get hasOwner => ownerId != null;

  /// SALE membership lifecycle under their OWNER:
  /// invited | active | suspended | unassigned.
  /// Falls back to ownerId for backends that don't yet return this field.
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

  /// Effective owner id: OWNER → self, SALE → their ownerId, otherwise null.
  String? get effectiveOwnerId => isOwner ? id : (isSale ? ownerId : null);

  // KYC helpers.
  bool get isKycApproved => kycStatus == 'approved';
  bool get isKycPending => kycStatus == 'pending';
  bool get isKycRejected => kycStatus == 'rejected';
  bool get isKycNone => kycStatus == 'none';

  /// OWNERs without an approved KYC are blocked from creating/editing
  /// properties. ADMIN and SALE don't go through KYC.
  bool get needsKyc => isOwner && !isKycApproved;

  /// Mutate permission for management data: ADMIN/OWNER always, SALE only
  /// when their membership is active.
  bool get canMutateManagementData =>
      isAdmin || isOwner || (isSale && isSaleMembershipActive);

  // Subscription helpers.
  bool get isInTrial => subscriptionStatus == 'trial';
  bool get isSubscriptionActive => subscriptionStatus == 'active';
  bool get isSubscriptionPastDue => subscriptionStatus == 'past_due';
  bool get isSubscriptionCancelled => subscriptionStatus == 'cancelled';
  bool get isSubscriptionExpired => subscriptionStatus == 'expired';

  /// Whole days left in the trial, or null when the user isn't in trial.
  int? get trialDaysLeft {
    if (!isInTrial || trialEndsAt == null) return null;
    final diff = trialEndsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Whole days left until the subscription expires (active/past_due/cancelled
  /// that still has access), or null when no expiry is known. Falls back to
  /// [trialEndsAt] while the backend hasn't started sending
  /// `subscriptionExpiresAt`.
  int? get subscriptionDaysLeft {
    final expiry = currentPeriodEnd ?? subscriptionExpiresAt ?? trialEndsAt;
    if (expiry == null) return null;
    final diff = expiry.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

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
    String? subscriptionProvider,
    DateTime? subscriptionExpiresAt,
    DateTime? trialEndsAt,
    DateTime? nextChargeAt,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    String? pendingPlanId,
    String? pendingCycle,
    DateTime? pendingEffectiveAt,
    DateTime? deletionScheduledAt,
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
        subscriptionProvider: subscriptionProvider ?? this.subscriptionProvider,
        subscriptionExpiresAt:
            subscriptionExpiresAt ?? this.subscriptionExpiresAt,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        nextChargeAt: nextChargeAt ?? this.nextChargeAt,
        currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
        pendingPlanId: pendingPlanId ?? this.pendingPlanId,
        pendingCycle: pendingCycle ?? this.pendingCycle,
        pendingEffectiveAt: pendingEffectiveAt ?? this.pendingEffectiveAt,
        deletionScheduledAt: deletionScheduledAt ?? this.deletionScheduledAt,
      );
}
