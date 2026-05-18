import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/plan.dart';
import '../../data/models/verify_enums.dart';
import 'verify_format.dart';

/// Plan card cho Screen 4.
///
/// 2 visual states:
/// 1. Default: border 1px borderDefault.
/// 2. Selected: border 2px brand + check icon corner.
///
/// Enterprise: shows "Contact us" instead of a price. Tap → caller redirects
/// to `/profile/help`.
class PlanCard extends StatelessWidget {
  final Plan plan;
  final BillingCycle cycle;
  final bool isSelected;
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.cycle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final borderColor = isSelected ? colors.brand : colors.borderDefault;
    final borderWidth = isSelected ? 2.0 : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              border: Border.all(color: borderColor, width: borderWidth),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.tier.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _roomLabel(plan),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.brandLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.tier.tagline,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PriceBlock(plan: plan, cycle: cycle),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: colors.borderSubtle),
                const SizedBox(height: 10),
                ...plan.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check, size: 14, color: colors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selected check icon (only for fixed-price plans)
        if (isSelected && plan.hasFixedPrice)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colors.brand,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: AppColors.darkBg,
              ),
            ),
          ),
      ],
    );
  }

  String _roomLabel(Plan plan) {
    if (plan.isEnterprise) return 'Không giới hạn';
    return '${plan.rooms} phòng';
  }
}

/// Show the price in the top-right of the card. Enterprise → "Contact us" + arrow.
class _PriceBlock extends StatelessWidget {
  final Plan plan;
  final BillingCycle cycle;
  const _PriceBlock({required this.plan, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!plan.hasFixedPrice) {
      // Enterprise — no fixed price
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Liên hệ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textBrand,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tư vấn',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward, size: 12, color: colors.textTertiary),
            ],
          ),
        ],
      );
    }

    final price = cycle == BillingCycle.yearly
        ? PlanPriceCalculator.yearlyAfterDiscount(plan)
        : PlanPriceCalculator.monthly(plan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          VerifyFormat.priceShort(price),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          cycle == BillingCycle.yearly ? '/ năm' : '/ tháng',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
