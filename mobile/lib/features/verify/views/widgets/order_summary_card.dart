import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/payment_history_item.dart';
import '../../data/models/payment_quote.dart';
import '../../data/models/plan.dart';
import '../../data/models/verify_enums.dart';
import 'verify_format.dart';

/// Order summary — hiển thị `breakdown` từ BE (quote / session).
class OrderSummaryCard extends StatelessWidget {
  final Plan plan;
  final BillingCycle cycle;
  final PaymentBreakdown breakdown;
  final PaymentHistoryKind? kind;
  final int totalAmount;

  const OrderSummaryCard({
    super.key,
    required this.plan,
    required this.cycle,
    required this.breakdown,
    required this.totalAmount,
    this.kind,
  });

  factory OrderSummaryCard.fromQuote({
    required Plan plan,
    required PaymentQuote quote,
  }) =>
      OrderSummaryCard(
        plan: plan,
        cycle: quote.cycle,
        breakdown: quote.breakdown,
        totalAmount: quote.totalAmount,
        kind: quote.kind,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isYearly = cycle == BillingCycle.yearly;
    final periodLabel = isYearly ? '12 tháng' : '1 tháng';
    final showTrialBadge = kind == PaymentHistoryKind.subscription;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHI TIẾT ĐƠN HÀNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          if (kind != null) ...[
            const SizedBox(height: 6),
            Text(
              kind!.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: colors.brandLight,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _line(
            context,
            label: '${plan.tier.displayName} × $periodLabel',
            value: VerifyFormat.priceVND(breakdown.listPrice),
          ),
          if (breakdown.creditApplied > 0) ...[
            const SizedBox(height: 8),
            _line(
              context,
              label: breakdown.remainingDays != null
                  ? 'Credit gói cũ (${breakdown.remainingDays} ngày)'
                  : 'Credit gói cũ',
              value: '-${VerifyFormat.priceVND(breakdown.creditApplied)}',
              valueColor: colors.success,
            ),
          ],
          if (breakdown.vat > 0) ...[
            const SizedBox(height: 8),
            _line(
              context,
              label: 'VAT 10%',
              value: '+${VerifyFormat.priceVND(breakdown.vat)}',
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                VerifyFormat.priceVND(totalAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textBrand,
                ),
              ),
            ],
          ),
          if (breakdown.periodExtension != null &&
              breakdown.periodExtension!.months > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successBgDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available, size: 14, color: colors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Gia hạn thêm ${breakdown.periodExtension!.months} tháng',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showTrialBadge) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successBgDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: colors.success),
                  const SizedBox(width: 6),
                  Text(
                    '7 ngày trial · Tính từ ngày được duyệt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
