import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/verify_flow_controller.dart';

/// Screen 1 — Paywall modal.
///
/// Trigger: Free Owner taps a locked action (create property / manage rooms
/// / revenue report). Modal explains the flow + 4-step preview.
///
/// Anatomy per spec section 5.1.
class PaywallModal extends ConsumerStatefulWidget {
  /// Called with the verify route to resume at (matches the "Tiếp tục bước X"
  /// label) so tapping "step 3" actually opens step 3, not step 1.
  final ValueChanged<String>? onProceed;
  final VoidCallback? onDefer;

  const PaywallModal({super.key, this.onProceed, this.onDefer});

  @override
  ConsumerState<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends ConsumerState<PaywallModal> {
  @override
  void initState() {
    super.initState();
    // Hydrate KYC state from backend when the modal opens — so we show the
    // right "Continue at step X" instead of always "Start now" even when a
    // draft exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(verifyFlowControllerProvider.notifier).hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm + 2,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderStrong,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Hero icon (gold rounded)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.home_outlined,
              size: 28,
              color: AppColors.goldMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            'Xác minh tài khoản',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppConfig.hidePaidUpgradeUI
                ? 'Xác minh CCCD + selfie để mở khoá tính năng quản lý.'
                : 'Xác minh CCCD để mở khoá tính năng quản lý. Bạn có thể chọn gói thanh toán sau khi admin duyệt.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step preview card — KYC only. Plan purchase is a separate flow
          // post-approval (decoupled from KYC).
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgCanvas,
              border: Border.all(color: colors.borderDefault),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUY TRÌNH ${_visibleSteps.length} BƯỚC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._visibleSteps.asMap().entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          bottom: e.key == _visibleSteps.length - 1 ? 0 : 10,
                        ),
                        child: _StepRow(
                          index: e.key + 1,
                          title: e.value.$1,
                          subtitle: e.value.$2,
                        )
                            .animate(delay: (60 * e.key).ms)
                            .fadeIn(duration: 240.ms)
                            .slideX(begin: -0.05, end: 0),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Buttons row.
          // NOTE: callbacks handle pop themselves (via `showPaywallModal`
          // helper). If we pop here before calling the callback, the modal
          // closes with a null result, so the caller's `await showPaywallModal()`
          // always receives null instead of true/false → `ok == true` check
          // fails → it would NOT navigate.
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Để sau',
                  onTap: () => widget.onDefer?.call(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: 'Bắt đầu xác thực',
                  trailingIcon: Icons.arrow_forward,
                  onTap: () {
                    // Always start fresh at CCCD front. Resuming mid-flow is
                    // unsafe: the backend needs every CCCD upload re-sent (it
                    // can't reconstruct cccdFrontId from a local draft), so
                    // skipping the capture screens makes submit fail with
                    // "please CCCD front". Clear any stale draft first.
                    ref
                        .read(verifyFlowControllerProvider.notifier)
                        .clearDraft();
                    widget.onProceed?.call('/verify/cccd-front');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
              children: [
                const TextSpan(
                    text: 'Tiếp tục đồng nghĩa với việc bạn đồng ý '),
                TextSpan(
                  text: 'Điều khoản dịch vụ',
                  style: TextStyle(
                    color: colors.brandLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Steps shown in the verify intro. iOS (Guideline 3.1.1) drops the
  /// "Chọn gói thanh toán" step — KYC alone unlocks management, no payment.
  static List<(String, String)> get _visibleSteps => [
        ('Chụp CCCD + Selfie', 'Xác minh danh tính cá nhân'),
        ('Chờ admin duyệt', 'Trong vòng 24 giờ'),
        if (AppConfig.showPaidUpgradeUI)
          ('Chọn gói thanh toán', 'Sau khi duyệt — chọn gói phù hợp số phòng'),
      ];
}

class _StepRow extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;

  const _StepRow({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colors.borderDefault,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textBrand,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.borderDefault,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.brand, // jadeText (#B5D4DA)
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBg, // dark text on light bg
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 16, color: AppColors.darkBg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper to show the paywall modal.
///
/// Returns:
/// - the verify route to push (`/verify/cccd-front`) if the user proceeds.
/// - `null` if the user taps "Later" / dismisses.
Future<String?> showPaywallModal(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: const Color(0x99000000),
    builder: (ctx) => PaywallModal(
      onProceed: (route) => Navigator.of(ctx).maybePop(route),
      onDefer: () => Navigator.of(ctx).maybePop(),
    ),
  );
}
