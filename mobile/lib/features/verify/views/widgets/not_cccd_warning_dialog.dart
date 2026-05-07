import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Dialog cảnh báo ảnh vừa chọn/chụp không nhận diện được CCCD.
///
/// Style theo design system: rounded card 20, warning amber theme, icon
/// trong khung tròn, title bold, body subtle, 2 button outlined +
/// filled-warning. Reuse cho cả gallery pick (cccd_capture_screen) và
/// manual shutter (cccd_scanner_screen).
///
/// Returns:
/// - `true` → user chọn "Vẫn upload"
/// - `false`/`null` → user chọn "Chụp lại" / dismiss
Future<bool?> showNotCccdWarning(
  BuildContext context, {
  required String? reason,
  String forceLabel = 'Vẫn upload',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _NotCccdWarningDialog(
      reason: reason,
      forceLabel: forceLabel,
    ),
  );
}

class _NotCccdWarningDialog extends StatelessWidget {
  final String? reason;
  final String forceLabel;

  const _NotCccdWarningDialog({
    required this.reason,
    required this.forceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon trong khung tròn warning ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 30,
                color: colors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Title ──
            Text(
              'Ảnh có thể không phải CCCD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // ── Body / reason ──
            Text(
              reason ??
                  'Hệ thống không nhận diện được CCCD trong ảnh. Bạn có chắc '
                      'muốn dùng ảnh này?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2 buttons ──
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderDefault),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Chụp lại',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.warning,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        forceLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
