import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';

/// Compact pagination: ‹  page  ›
class AppPaginationBar extends StatelessWidget {
  /// Current page (0-based).
  final int currentPage;

  final int totalPages;

  final VoidCallback? onPrevious;

  final VoidCallback? onNext;

  const AppPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPrev = onPrevious != null;
    final canNext = onNext != null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _RoundNavButton(
              icon: Icons.chevron_left_rounded,
              enabled: canPrev,
              onTap: onPrevious,
              colors: colors,
              isDark: isDark,
            ),
            Expanded(
              child: Text(
                '${currentPage + 1}/$totalPages',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _RoundNavButton(
              icon: Icons.chevron_right_rounded,
              enabled: canNext,
              onTap: onNext,
              colors: colors,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundNavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final AppColorScheme colors;
  final bool isDark;

  const _RoundNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled
        ? colors.textBrand
        : colors.textTertiary.withValues(alpha: 0.45);
    final bg = enabled
        ? (isDark
            ? colors.brand.withValues(alpha: 0.18)
            : colors.brand.withValues(alpha: 0.10))
        : colors.bgSurfaceContainer;

    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 24, color: fg),
        ),
      ),
    );
  }
}
