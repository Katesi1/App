import '../../../data/models/user_model.dart';
import '../data/models/payment_history_item.dart';
import '../data/models/payment_quote.dart';
import '../data/models/verify_enums.dart';

/// Helper copy + tính ngày dự kiến cho quote (renew stack / upgrade).
class BillingQuoteHelper {
  BillingQuoteHelper._();

  /// `baseDate = max(currentPeriodEnd, now)` + 1 period theo cycle mới.
  static DateTime? projectedPeriodEnd({
    required DateTime? currentPeriodEnd,
    required BillingCycle newCycle,
  }) {
    final now = DateTime.now();
    final base = currentPeriodEnd != null && currentPeriodEnd.isAfter(now)
        ? currentPeriodEnd
        : now;
    return switch (newCycle) {
      BillingCycle.yearly => base.add(const Duration(days: 365)),
      BillingCycle.monthly => base.add(const Duration(days: 30)),
    };
  }

  static bool isCycleChange({
    required String? userCycle,
    required BillingCycle quoteCycle,
  }) {
    if (userCycle == null || userCycle.isEmpty) return false;
    return userCycle != quoteCycle.name;
  }

  static String? renewStackNote({
    required PaymentQuote quote,
    required UserModel? user,
    required bool hasPendingPaymentSession,
  }) {
    if (quote.kind != PaymentHistoryKind.renew) return null;
    if (hasPendingPaymentSession) {
      return 'Hạn sẽ được cộng thêm khi admin duyệt thanh toán. '
          'Hiện tại vẫn là hạn kỳ cũ trên tài khoản.';
    }
    final projected = projectedPeriodEnd(
      currentPeriodEnd: user?.currentPeriodEnd,
      newCycle: quote.cycle,
    );
    if (projected == null) {
      return 'Cộng dồn vào kỳ hiện tại khi admin duyệt thanh toán.';
    }
    return 'Cộng dồn vào kỳ hiện tại. '
        'Hạn mới dự kiến sau khi duyệt: '
        '${projected.day.toString().padLeft(2, '0')}/'
        '${projected.month.toString().padLeft(2, '0')}/'
        '${projected.year}.';
  }

  static String? upgradeCreditNote({
    required PaymentBreakdown breakdown,
    required UserModel? user,
  }) {
    if (breakdown.creditApplied <= 0) return null;
    final remaining = breakdown.remainingDays;
    final total = breakdown.totalDays;
    final planLabel = breakdown.currentPlanId != null
        ? UserModel.planLabelFor(breakdown.currentPlanId)
        : user?.subscriptionPlanLabel;
    if (remaining != null && total != null && total > 0) {
      return 'Bạn còn $remaining/$total ngày gói ${planLabel ?? 'hiện tại'} '
          '→ được trừ ${_formatVnd(breakdown.creditApplied)}.';
    }
    return 'Credit gói cũ: -${_formatVnd(breakdown.creditApplied)}.';
  }

  static String? cycleDeferNote({
    required PaymentQuote quote,
    required UserModel? user,
  }) {
    if (quote.kind != PaymentHistoryKind.upgrade) return null;
    if (!isCycleChange(
      userCycle: user?.subscriptionCycle,
      quoteCycle: quote.cycle,
    )) {
      return null;
    }
    final end = user?.currentPeriodEnd;
    if (end == null) {
      return 'Chu kỳ ${quote.cycle.name == 'yearly' ? 'năm' : 'tháng'} '
          'sẽ áp dụng từ kỳ gia hạn tiếp theo.';
    }
    return 'Chu kỳ ${quote.cycle.name == 'yearly' ? 'năm' : 'tháng'} '
        'sẽ áp dụng từ kỳ gia hạn tiếp theo (sau ngày '
        '${end.day.toString().padLeft(2, '0')}/'
        '${end.month.toString().padLeft(2, '0')}/'
        '${end.year}).';
  }

  static String _formatVnd(int amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return m == m.roundToDouble()
          ? '${m.toInt()}tr'
          : '${m.toStringAsFixed(1)}tr';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(0)}k';
    }
    return '$amountđ';
  }
}
