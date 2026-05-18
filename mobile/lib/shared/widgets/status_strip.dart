import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';

/// Status Strip pattern — context info bar used anywhere we need an info
/// line like "paid", "upcoming", "occupied", "X rooms left".
///
/// Anatomy:
/// - 3px border-left rail in the variant's colour
/// - Subtle tonal background (alpha 8% light, 16% dark)
/// - Icon (small, theo variant color)
/// - Label (w600 size 12) + optional subtitle (size 11 textSecondary)
/// - Trailing widget optional (CTA/value)
enum StatusStripVariant { brand, success, warning, error, info, neutral }

class StatusStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final StatusStripVariant variant;
  final EdgeInsetsGeometry? padding;

  const StatusStrip({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.variant = StatusStripVariant.brand,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _resolveColor(colors);
    final bgAlpha = isDark ? 0.16 : 0.08;

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: bgAlpha),
        border: Border(
          left: BorderSide(color: c, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadius.sm),
          bottomRight: Radius.circular(AppRadius.sm),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }

  Color _resolveColor(AppColorScheme colors) {
    switch (variant) {
      case StatusStripVariant.brand:
        return colors.brand;
      case StatusStripVariant.success:
        return colors.success;
      case StatusStripVariant.warning:
        return colors.warning;
      case StatusStripVariant.error:
        return colors.error;
      case StatusStripVariant.info:
        return colors.info;
      case StatusStripVariant.neutral:
        return colors.textTertiary;
    }
  }
}
