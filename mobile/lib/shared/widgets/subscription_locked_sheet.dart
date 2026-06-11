import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';

/// Handles the BE entitlement gate (`subscription.featureLocked`, API_SPEC
/// §2A.5). BE returns it on `POST /properties`, `PUT /properties/:id`,
/// `POST /staff/invites` once an OWNER's silent 60-day trial expires without a
/// paid plan. The generic message is intentionally vague so iOS never reveals
/// the subscription state (Apple Guideline 3.1.1).
///
/// The CTA differs per platform:
/// - **iOS**: contact-support only — NO "thanh toán / gói / gia hạn / trial".
/// - **Android / Web**: routes to the plan picker to pay (bank transfer flow).
class SubscriptionLock {
  SubscriptionLock._();

  /// Machine-readable code BE sends in the error envelope root.
  static const code = 'subscription.featureLocked';

  /// Detects the entitlement-locked error from the BE `code` (preferred) or,
  /// as a fallback, the localized message text (vi/en). Chuẩn hoá bỏ ký tự
  /// không phải chữ để match cả `subscription.featureLocked` lẫn code mới
  /// `FEATURE_LOCKED` (BE đổi sang code ổn định cho 403).
  static bool isLocked({String? code, String? message}) {
    final normalized = code?.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (normalized != null && normalized.contains('featurelocked')) {
      return true;
    }
    if (message == null) return false;
    final m = message.toLowerCase();
    return m.contains('chưa có quyền dùng tính năng') ||
        m.contains('not authorized to use this feature');
  }

  /// If [code]/[message] indicate the entitlement lock, fires the platform
  /// sheet and returns `true`. Otherwise returns `false` so the caller can fall
  /// back to its normal error snackbar. Synchronous — the decision is made
  /// before the sheet's lifecycle, so callers can branch immediately:
  ///
  /// ```dart
  /// if (!SubscriptionLock.maybeHandle(context, code: c, message: m)) {
  ///   AppSnackBar.error(context, m);
  /// }
  /// ```
  static bool maybeHandle(
    BuildContext context, {
    String? code,
    String? message,
  }) {
    if (!isLocked(code: code, message: message)) return false;
    show(context);
    return true;
  }

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LockedSheet(),
    );
  }
}

class _LockedSheet extends StatelessWidget {
  const _LockedSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIOS = AppConfig.hidePaidUpgradeUI;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.warningBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: 26, color: colors.warning),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chưa thể dùng tính năng này',
            style: GoogleFonts.beVietnamPro(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isIOS
                ? 'Tài khoản của bạn hiện chưa có quyền dùng tính năng này. '
                    'Vui lòng liên hệ bộ phận hỗ trợ để được trợ giúp.'
                : 'Tài khoản chưa có quyền dùng tính năng này. '
                    'Chọn gói dịch vụ phù hợp để tiếp tục.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isIOS)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _contactSupport();
              },
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: Text(
                'Liên hệ hỗ trợ',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
              ),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/verify/select-plan');
              },
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: Text(
                'Xem gói dịch vụ',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Để sau',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: 'subject=${Uri.encodeComponent('Hỗ trợ tài khoản Halong24h')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
