/// Snapshot subscription của một OWNER — trả về bởi
/// GET /admin/users/:id/subscription.
class TrialSnapshot {
  final String userId;
  final String userName;
  final String userPhone;
  final String? userEmail;

  /// none | trial | active | past_due | cancelled
  final String subscriptionStatus;

  /// starter | professional | enterprise | null
  final String? planId;

  /// monthly | yearly | null
  final String? cycle;

  final int? rooms;
  final DateTime? trialEndsAt;
  final DateTime? nextChargeAt;
  final DateTime? activatedAt;

  const TrialSnapshot({
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    required this.subscriptionStatus,
    this.planId,
    this.cycle,
    this.rooms,
    this.trialEndsAt,
    this.nextChargeAt,
    this.activatedAt,
  });

  bool get hasActiveTrial =>
      subscriptionStatus == 'trial' &&
      (trialEndsAt == null || trialEndsAt!.isAfter(DateTime.now()));

  bool get isActive => subscriptionStatus == 'active';

  bool get hasPlan => planId != null && planId!.isNotEmpty;

  factory TrialSnapshot.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return TrialSnapshot(
      userId: (json['userId'] as String?) ?? (user['id'] as String?) ?? '',
      userName: (user['name'] as String?) ?? '',
      userPhone: (user['phone'] as String?) ?? '',
      userEmail: user['email'] as String?,
      subscriptionStatus:
          (json['subscriptionStatus'] as String?) ?? 'none',
      planId: json['planId'] as String?,
      cycle: json['cycle'] as String?,
      rooms: (json['rooms'] as num?)?.toInt(),
      trialEndsAt: _parseDate(json['trialEndsAt']),
      nextChargeAt: _parseDate(json['nextChargeAt']),
      activatedAt: _parseDate(json['activatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

/// Kết quả action grant / revoke trial.
class TrialActionResult {
  final String userId;

  /// granted | extended | revoked
  final String action;

  final int? days;
  final String? planId;
  final String? cycle;
  final int? rooms;
  final DateTime? trialEndsAt;

  const TrialActionResult({
    required this.userId,
    required this.action,
    this.days,
    this.planId,
    this.cycle,
    this.rooms,
    this.trialEndsAt,
  });

  factory TrialActionResult.fromJson(Map<String, dynamic> json) {
    return TrialActionResult(
      userId: (json['userId'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      days: (json['days'] as num?)?.toInt(),
      planId: json['planId'] as String?,
      cycle: json['cycle'] as String?,
      rooms: (json['rooms'] as num?)?.toInt(),
      trialEndsAt: TrialSnapshot._parseDate(json['trialEndsAt']),
    );
  }
}
