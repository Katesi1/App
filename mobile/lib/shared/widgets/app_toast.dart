import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum AppToastType { success, error, info, warning }

/// Toast phía trên màn hình (Toastify-style) — icon + accent + message.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.info);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.warning);

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;
    hide();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final effectiveDuration = duration ??
        (onAction != null
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastBanner(
        message: message,
        type: type,
        topInset: MediaQuery.of(ctx).padding.top,
        onTapDismiss: () {
          if (_entry == entry) hide();
        },
        actionLabel: actionLabel,
        onAction: onAction != null
            ? () {
                hide();
                onAction();
              }
            : null,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(effectiveDuration, hide);
  }
}

class _ToastBanner extends StatelessWidget {
  final String message;
  final AppToastType type;
  final double topInset;
  final VoidCallback onTapDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastBanner({
    required this.message,
    required this.type,
    required this.topInset,
    required this.onTapDismiss,
    this.actionLabel,
    this.onAction,
  });

  ({
    Color accent,
    Color iconBg,
    Color background,
    Color border,
    IconData icon,
  }) _style(AppColorScheme colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (type) {
      case AppToastType.success:
        return (
          accent: colors.success,
          iconBg: colors.success.withValues(alpha: isDark ? 0.22 : 0.18),
          background: colors.successBg,
          border: colors.success.withValues(alpha: isDark ? 0.5 : 0.4),
          icon: Icons.check_circle_outline_rounded,
        );
      case AppToastType.error:
        return (
          accent: colors.error,
          iconBg: colors.error.withValues(alpha: isDark ? 0.22 : 0.18),
          background: colors.errorBg,
          border: colors.error.withValues(alpha: isDark ? 0.5 : 0.4),
          icon: Icons.error_outline_rounded,
        );
      case AppToastType.warning:
        return (
          accent: colors.warning,
          iconBg: colors.warning.withValues(alpha: isDark ? 0.22 : 0.18),
          background: colors.warningBg,
          border: colors.warning.withValues(alpha: isDark ? 0.5 : 0.4),
          icon: Icons.warning_amber_rounded,
        );
      case AppToastType.info:
        return (
          accent: colors.info,
          iconBg: colors.info.withValues(alpha: isDark ? 0.22 : 0.15),
          background: isDark ? AppColors.infoBgDark : AppColors.jade50,
          border: colors.info.withValues(alpha: isDark ? 0.5 : 0.35),
          icon: Icons.info_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final style = _style(colors, brightness);

    return Positioned(
      top: topInset + AppSpacing.sm,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTapDismiss,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: style.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: style.accent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: style.accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.xs,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: style.iconBg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                style.icon,
                                size: 20,
                                color: style.accent,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (onAction != null) ...[
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: onAction,
                                        child: Text(
                                          actionLabel ?? 'Xem',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: style.accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: onTapDismiss,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: colors.textTertiary,
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
          ),
        ),
      ).animate().fadeIn(duration: 220.ms, curve: Curves.easeOut).slideY(
            begin: -0.15,
            end: 0,
            duration: 280.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
