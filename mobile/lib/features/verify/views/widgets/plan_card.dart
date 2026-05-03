import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/plan.dart';
import '../../data/models/verify_enums.dart';
import 'verify_format.dart';

/// Plan card cho Screen 4.
///
/// 3 visual states:
/// 1. Default: border 1px borderDefault.
/// 2. Suggested (Pro): border 2px brandLight + ribbon "PHỔ BIẾN NHẤT".
/// 3. Selected: border 2px brand + check icon corner.
class PlanCard extends StatelessWidget {
  final Plan plan;
  final int rooms;
  final BillingCycle cycle;
  final bool isSuggested;
  final bool isSelected;
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.rooms,
    required this.cycle,
    required this.isSuggested,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final price = cycle == BillingCycle.yearly
        ? PlanPriceCalculator.yearlyAfterDiscount(rooms, plan)
        : PlanPriceCalculator.monthly(rooms, plan);

    final borderColor = isSelected
        ? colors.brand
        : (isSuggested ? colors.brandLight : colors.borderDefault);
    final borderWidth = (isSelected || isSuggested) ? 2.0 : 1.0;

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
                            _roomRange(plan),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colors.textTertiary,
                            ),
                          ),
                          if (isSuggested) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Phù hợp với bạn',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.brandLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
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
                    ),
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

        // Ribbon "PHỔ BIẾN NHẤT"
        if (isSuggested)
          Positioned(
            top: -8,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.brandLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PHỔ BIẾN NHẤT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppColors.darkBg,
                ),
              ),
            ),
          ),

        // Selected check icon
        if (isSelected)
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

  String _roomRange(Plan plan) {
    if (plan.maxRooms == null) return 'Không giới hạn phòng';
    return 'Đến ${plan.maxRooms} phòng';
  }
}
