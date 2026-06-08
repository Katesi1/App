/// Quota phòng theo gói subscription — khớp `BillingPlan.maxRooms` trên BE.
class RoomEntitlement {
  RoomEntitlement._();

  /// `null` = không giới hạn (enterprise).
  static int? maxRoomsForPlanId(String? planId) {
    if (planId == null || planId.isEmpty) return 0;
    return switch (planId) {
      'rooms_1' || 'mini' || 'starter_test' => 1,
      'rooms_5' || 'starter' => 5,
      'rooms_10' || 'standard' => 10,
      'rooms_20' || 'pro' || 'professional' => 20,
      'rooms_50' || 'business' => 50,
      'enterprise' || 'rooms_unlimited' => null,
      _ => 0,
    };
  }

  static bool canAddRooms({
    required String? planId,
    required int currentRoomCount,
    int adding = 1,
  }) {
    final max = maxRoomsForPlanId(planId);
    if (max == null) return true;
    return currentRoomCount + adding <= max;
  }

  static String atLimitMessage({
    required String? planId,
    required int currentCount,
    required String planLabel,
  }) {
    final max = maxRoomsForPlanId(planId);
    if (max == null) return '';
    return 'Đã dùng $currentCount/$max phòng của gói $planLabel. '
        'Nâng cấp gói để thêm phòng.';
  }
}
