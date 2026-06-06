import 'package:equatable/equatable.dart';

import 'payment_history_item.dart';
import 'plan.dart';
import 'verify_enums.dart';

/// Gia hạn thêm N tháng sau mark-paid (renew / subscription).
class PeriodExtension extends Equatable {
  final int months;

  const PeriodExtension({required this.months});

  factory PeriodExtension.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PeriodExtension(months: 0);
    return PeriodExtension(months: (json['months'] as num?)?.toInt() ?? 0);
  }

  @override
  List<Object?> get props => [months];
}

/// Chi tiết tiền do BE tính — FE chỉ hiển thị.
class PaymentBreakdown extends Equatable {
  final int listPrice;
  final int creditApplied;
  final int vat;
  final int? remainingDays;
  final int? totalDays;
  final String? currentPlanId;
  final PeriodExtension? periodExtension;

  const PaymentBreakdown({
    required this.listPrice,
    required this.creditApplied,
    required this.vat,
    this.remainingDays,
    this.totalDays,
    this.currentPlanId,
    this.periodExtension,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaymentBreakdown(
        listPrice: 0,
        creditApplied: 0,
        vat: 0,
      );
    }
    final extRaw = json['periodExtension'];
    return PaymentBreakdown(
      listPrice: (json['listPrice'] as num?)?.toInt() ?? 0,
      creditApplied: (json['creditApplied'] as num?)?.toInt() ?? 0,
      vat: (json['vat'] as num?)?.toInt() ?? 0,
      remainingDays: (json['remainingDays'] as num?)?.toInt(),
      totalDays: (json['totalDays'] as num?)?.toInt(),
      currentPlanId: json['currentPlanId'] as String?,
      periodExtension: extRaw is Map<String, dynamic>
          ? PeriodExtension.fromJson(extRaw)
          : null,
    );
  }

  int get totalAmount => listPrice - creditApplied + vat;

  @override
  List<Object?> get props => [
        listPrice,
        creditApplied,
        vat,
        remainingDays,
        totalDays,
        currentPlanId,
        periodExtension,
      ];
}

/// Kết quả `POST /payments/quote` — read-only, không tạo session.
class PaymentQuote extends Equatable {
  final PaymentHistoryKind kind;
  final String planId;
  final BillingCycle cycle;
  final int rooms;
  final int totalAmount;
  final PaymentBreakdown breakdown;
  final DateTime? effectiveAt;
  final String? pendingPlanId;

  /// `true` khi BE `/payments/quote` lỗi — FE dùng giá catalog tạm.
  final bool isCatalogFallback;

  bool get isDowngrade => kind == PaymentHistoryKind.downgrade;

  const PaymentQuote({
    required this.kind,
    required this.planId,
    required this.cycle,
    required this.rooms,
    required this.totalAmount,
    required this.breakdown,
    this.effectiveAt,
    this.pendingPlanId,
    this.isCatalogFallback = false,
  });

  factory PaymentQuote.fromJson(Map<String, dynamic> json) {
    final breakdownRaw = json['breakdown'];
    final totalFromApi = (json['totalAmount'] as num?)?.toInt();
    final breakdown = PaymentBreakdown.fromJson(
      breakdownRaw is Map<String, dynamic> ? breakdownRaw : null,
    );
    return PaymentQuote(
      kind: _kindFromApi(json['kind'] as String? ?? 'subscription'),
      planId: (json['planId'] as String?) ?? '',
      cycle: (json['cycle'] as String? ?? 'monthly') == 'yearly'
          ? BillingCycle.yearly
          : BillingCycle.monthly,
      rooms: (json['rooms'] as num?)?.toInt() ?? 0,
      totalAmount: totalFromApi ?? breakdown.totalAmount,
      breakdown: breakdown,
      effectiveAt: _parseDate(json['effectiveAt']),
      pendingPlanId: json['pendingPlanId'] as String?,
    );
  }

  /// Fallback khi BE chưa có `/payments/quote` hoặc lỗi mạng.
  factory PaymentQuote.fromCatalog(
    Plan plan,
    BillingCycle cycle, {
    PaymentHistoryKind kind = PaymentHistoryKind.subscription,
  }) {
    final subtotal = cycle == BillingCycle.yearly
        ? PlanPriceCalculator.yearlyAfterDiscount(plan)
        : PlanPriceCalculator.monthly(plan);
    final vat = PlanPriceCalculator.vat(subtotal);
    final months = cycle == BillingCycle.yearly ? 12 : 1;
    return PaymentQuote(
      kind: kind,
      planId: plan.id,
      cycle: cycle,
      rooms: plan.rooms > 0 ? plan.rooms : 1,
      totalAmount: subtotal + vat,
      breakdown: PaymentBreakdown(
        listPrice: subtotal,
        creditApplied: 0,
        vat: vat,
        periodExtension: PeriodExtension(months: months),
      ),
      isCatalogFallback: true,
    );
  }

  @override
  List<Object?> get props => [
        kind,
        planId,
        cycle,
        rooms,
        totalAmount,
        breakdown,
        effectiveAt,
        pendingPlanId,
        isCatalogFallback,
      ];
}

PaymentHistoryKind _kindFromApi(String raw) {
  switch (raw.toLowerCase()) {
    case 'renew':
    case 'renewal':
      return PaymentHistoryKind.renew;
    case 'upgrade':
      return PaymentHistoryKind.upgrade;
    case 'downgrade':
      return PaymentHistoryKind.downgrade;
    case 'refund':
      return PaymentHistoryKind.refund;
    case 'subscription':
    default:
      return PaymentHistoryKind.subscription;
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null || raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
