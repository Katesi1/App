import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Brand identity card cho aggregated screens (Dashboard, Customer Home,
/// Bookings overview, Reports).
///
/// Spec: `halong24h-component-specs-v2.md` section "Card AI insight".
///
/// Anatomy:
/// - Background gradient gold (alpha 12% → 4% light, mạnh hơn dark)
/// - Border 1px gold 30%
/// - Icon container 36×36 nền gold500 với shadow gold
/// - Overline "GỢI Ý TỪ AI" w800 size 11 — gold700 light / goldBright dark
/// - Message body — textPrimary
/// - 2 action button optional (primary filled gold + outlined)
/// - Dismiss button optional (top-right close)
class AIInsightCard extends StatelessWidget {
  final String message;
  final String overline;
  final IconData icon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onDismiss;

  const AIInsightCard({
    super.key,
    required this.message,
    this.overline = 'GỢI Ý TỪ AI',
    this.icon = Icons.auto_awesome_rounded,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgStartAlpha = isDark ? 0.20 : 0.12;
    final bgEndAlpha = isDark ? 0.08 : 0.04;
    final borderAlpha = isDark ? 0.45 : 0.30;
    final iconShadowAlpha = isDark ? 0.50 : 0.30;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold500.withValues(alpha: bgStartAlpha),
            AppColors.gold300.withValues(alpha: bgEndAlpha),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.gold500.withValues(alpha: borderAlpha),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold500,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold500
                          .withValues(alpha: iconShadowAlpha),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 20,
                  // Light: white trên gold500 OK; dark: gold900 cho contrast
                  color: isDark ? AppColors.gold900 : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // Overline + body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overline,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colors.textBrandAccent, // gold700 / goldBright
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          if (primaryActionLabel != null || secondaryActionLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (primaryActionLabel != null)
                  _PrimaryAction(
                    label: primaryActionLabel!,
                    onTap: onPrimaryAction,
                    isDark: isDark,
                  ),
                if (primaryActionLabel != null &&
                    secondaryActionLabel != null)
                  const SizedBox(width: 8),
                if (secondaryActionLabel != null)
                  _SecondaryAction(
                    label: secondaryActionLabel!,
                    onTap: onSecondaryAction,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  const _PrimaryAction({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.gold500,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            // Spec: light white / dark gold900 — contrast tốt cả 2 mode
            color: isDark ? AppColors.gold900 : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SecondaryAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.gold500),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            // gold700 cho text trên light; goldBright dark — qua textBrandAccent
            color: colors.textBrandAccent,
          ),
        ),
      ),
    );
  }
}
