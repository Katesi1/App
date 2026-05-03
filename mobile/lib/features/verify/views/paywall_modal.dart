import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/verify_flow_controller.dart';

/// Screen 1 — Paywall modal.
///
/// Trigger: Free Owner click action bị lock (Tạo property / Quản lý phòng /
/// Báo cáo doanh thu). Modal hiện giải thích flow + 4 step preview.
///
/// Anatomy theo spec section 5.1.
class PaywallModal extends ConsumerWidget {
  final VoidCallback? onProceed;
  final VoidCallback? onDefer;

  const PaywallModal({super.key, this.onProceed, this.onDefer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final hasDraft = state.currentStep > 1;
    final draftStep = state.currentStep;

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
            'Đăng phòng để kiếm tiền',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Để bắt đầu nhận booking, bạn cần verify CCCD và mua gói subscription.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4 step preview card
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
                  'QUY TRÌNH 4 BƯỚC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._steps.asMap().entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          bottom: e.key == _steps.length - 1 ? 0 : 10,
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
          // CHÚ Ý: callbacks tự handle pop (qua `showPaywallModal` helper).
          // Nếu pop ở đây trước khi gọi callback, modal close với result null,
          // làm caller `await showPaywallModal()` luôn nhận null thay vì
          // true/false → check `ok == true` ở caller fail → KHÔNG navigate.
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Để sau',
                  onTap: () => onDefer?.call(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: hasDraft
                      ? 'Tiếp tục bước $draftStep'
                      : 'Bắt đầu ngay',
                  trailingIcon: Icons.arrow_forward,
                  onTap: () => onProceed?.call(),
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
                const TextSpan(text: 'Tiếp tục đồng nghĩa với việc bạn đồng ý '),
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

  /// 4 bước verify flow — title + subtitle.
  static const List<(String, String)> _steps = [
    ('Chụp CCCD + Selfie', 'Xác minh danh tính cá nhân'),
    ('Thông tin homestay', 'Tên, địa chỉ, số phòng dự kiến'),
    ('Chọn gói + Thanh toán', '3 tier · Trial 7 ngày miễn phí'),
    ('Chờ admin duyệt', 'Trong vòng 24 giờ'),
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

/// Helper hiển thị paywall modal.
///
/// Returns:
/// - `true` nếu user tap "Bắt đầu ngay" (caller nên push verify flow)
/// - `false` nếu user tap "Để sau" / dismiss
Future<bool?> showPaywallModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: const Color(0x99000000),
    builder: (ctx) => PaywallModal(
      onProceed: () => Navigator.of(ctx).maybePop(true),
      onDefer: () => Navigator.of(ctx).maybePop(false),
    ),
  );
}
