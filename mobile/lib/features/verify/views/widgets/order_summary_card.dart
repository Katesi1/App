import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/plan.dart';
import '../../data/models/verify_enums.dart';
import 'verify_format.dart';

/// Order summary card for Screen 5 — detailed price breakdown.
///
/// Anatomy (signature pattern spec section 5.5):
/// - Card bg bgSurface, border 1px borderDefault, radius 12, padding 14
/// - Each line: label left + value right (12px w500/w700)
/// - Discount line: value successText
/// - Divider 1px borderSubtle
/// - Total: label 13px w700 + value 18px w800 jadeText
/// - Trial badge at the bottom: bg successBg, text successText, padding 6×10, radius 8
class OrderSummaryCard extends StatelessWidget {
  final Plan plan;
  final BillingCycle cycle;
  final bool includeVat;

  const OrderSummaryCard({
    super.key,
    required this.plan,
    required this.cycle,
    this.includeVat = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isYearly = cycle == BillingCycle.yearly;
    final base = isYearly
        ? PlanPriceCalculator.yearlyBeforeDiscount(plan)
        : PlanPriceCalculator.monthly(plan);
    final savings = isYearly ? PlanPriceCalculator.yearlySavings(plan) : 0;
    final subtotal = base - savings;
    final vat = includeVat ? PlanPriceCalculator.vat(subtotal) : 0;
    final total = subtotal + vat;

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
          const SizedBox(height: 12),
          _line(
            context,
            label:
                '${plan.tier.displayName} × ${isYearly ? "12 tháng" : "1 tháng"}',
            value: VerifyFormat.priceVND(base),
          ),
          if (isYearly) ...[
            const SizedBox(height: 8),
            _line(
              context,
              label: 'Giảm năm (-20%)',
              value: '-${VerifyFormat.priceVND(savings)}',
              valueColor: colors.success,
            ),
          ],
          if (includeVat) ...[
            const SizedBox(height: 8),
            _line(
              context,
              label: 'VAT 10%',
              value: '+${VerifyFormat.priceVND(vat)}',
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
                VerifyFormat.priceVND(total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textBrand, // jadeText
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Trial badge
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
