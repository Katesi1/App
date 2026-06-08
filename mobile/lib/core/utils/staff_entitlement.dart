/// Quyền mời nhân viên SALE theo gói subscription.
///
/// Khớp bảng tier trong `docs/DU_AN_DAU_TU.md` §9:
/// Mini=0, Starter/Standard=3, Pro/Business/Enterprise=không giới hạn.
class StaffEntitlement {
  StaffEntitlement._();

  /// Số slot SALE tối đa. `null` = không giới hạn. `0` = không được mời.
  static int? maxSlotsForPlanId(String? planId) {
    if (planId == null || planId.isEmpty) return 0;
    return switch (planId) {
      'rooms_1' || 'mini' || 'starter_test' => 0,
      'rooms_5' || 'starter' => 3,
      'rooms_10' || 'standard' => 3,
      'rooms_20' || 'pro' || 'professional' => null,
      'rooms_50' || 'business' => null,
      'enterprise' || 'rooms_unlimited' => null,
      _ => 0,
    };
  }

  static bool allowsInvite(String? planId) {
    final slots = maxSlotsForPlanId(planId);
    return slots == null || slots > 0;
  }

  /// Gói thấp nhất có quyền mời nhân viên.
  static const String minPlanLabel = 'Starter';

  static String slotsLabel(String? planId) {
    final slots = maxSlotsForPlanId(planId);
    if (slots == null) return 'Không giới hạn';
    if (slots == 0) return 'Không hỗ trợ';
    return 'Tối đa $slots';
  }
}
