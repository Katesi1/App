import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/user_model.dart';
import '../../data/models/plan.dart';
import '../../data/models/verify_enums.dart';
/// Hero card tóm tắt gói subscription — gradient + status pill.
class SubscriptionHeroCard extends StatelessWidget {
  final UserModel user;
  final Plan? plan;
  final BillingCycle billingCycle;

  /// Chi phí/kỳ do BE quote — đã format (vd `658.900đ`).
  final String costLabel;

  const SubscriptionHeroCard({
    super.key,
    required this.user,
    required this.plan,
    required this.billingCycle,
    required this.costLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade900, AppColors.jade300];

    final planName = plan?.tier.displayName ?? user.subscriptionPlanLabel;
    final roomLabel = _roomLabel(plan);
    final status = _StatusVisual.fromUser(user);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.jade500.withValues(alpha: isDark ? 0.2 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status.bgColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: status.fgColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 12, color: status.fgColor),
                        const SizedBox(width: 4),
                        Text(
                          status.label,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: status.fgColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.gold500.withValues(alpha: 0.85),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                planName,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                roomLabel,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              if (user.isInTrial && user.trialDaysLeft != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Còn ${user.trialDaysLeft} ngày dùng thử',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold50,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (plan != null && plan!.hasFixedPrice) ...[
                    Text(
                      costLabel,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        billingCycle == BillingCycle.yearly
                            ? '/ năm'
                            : '/ tháng',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      'Liên hệ tư vấn',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .slideY(begin: 0.08, end: 0, duration: 320.ms);
  }

  String _roomLabel(Plan? plan) {
    if (plan == null) return 'Gói đăng ký Halong24h';
    if (plan.isEnterprise) return 'Không giới hạn phòng';
    return 'Tối đa ${plan.rooms} phòng';
  }
}

class _StatusVisual {
  final String label;
  final IconData icon;
  final Color fgColor;
  final Color bgColor;

  const _StatusVisual({
    required this.label,
    required this.icon,
    required this.fgColor,
    required this.bgColor,
  });

  static _StatusVisual fromUser(UserModel user) {
    if (user.isInTrial) {
      return const _StatusVisual(
        label: 'Dùng thử',
        icon: Icons.hourglass_top_rounded,
        fgColor: AppColors.gold50,
        bgColor: AppColors.gold500,
      );
    }
    if (user.isSubscriptionActive) {
      return const _StatusVisual(
        label: 'Đang hoạt động',
        icon: Icons.check_circle_outline,
        fgColor: AppColors.success,
        bgColor: AppColors.success,
      );
    }
    if (user.isSubscriptionPastDue) {
      return const _StatusVisual(
        label: 'Quá hạn',
        icon: Icons.warning_amber_rounded,
        fgColor: AppColors.warning,
        bgColor: AppColors.warning,
      );
    }
    if (user.isSubscriptionCancelled) {
      return const _StatusVisual(
        label: 'Đã huỷ',
        icon: Icons.cancel_outlined,
        fgColor: AppColors.error,
        bgColor: AppColors.error,
      );
    }
    return const _StatusVisual(
      label: 'Chưa kích hoạt',
      icon: Icons.info_outline,
      fgColor: Colors.white70,
      bgColor: Colors.white,
    );
  }
}

/// Ô metric nhỏ trong grid chi tiết gói.
class SubscriptionMetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const SubscriptionMetricTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
