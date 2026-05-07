import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import 'widgets/trial_countdown_text.dart';
import 'widgets/verify_format.dart';

/// Screen 7 — Trial active sau khi admin duyệt.
class TrialActiveScreen extends ConsumerWidget {
  const TrialActiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final plan = state.selectedPlan;
    final trialEnds =
        state.trialEndsAt ?? DateTime.now().add(const Duration(days: 7));
    final chargeStarts = state.chargeStartsAt ?? trialEnds;
    final total =
        plan == null ? 0 : PlanPriceCalculator.total(plan, state.billingCycle);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      // AppBar tối giản — chỉ hiện nút X để dismiss về dashboard.
      // User landed ở đây qua `pushReplacement` từ pending screen nên
      // navigation stack rỗng → cần explicit exit point.
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            color: colors.textSecondary,
            tooltip: 'Đóng',
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SuccessBanner(trialEndsAt: trialEnds).animate().slideY(
                begin: -0.5,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _StartHereCard()
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 320.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  if (plan != null)
                    _SubscriptionCard(
                      plan: plan,
                      cycle: state.billingCycle,
                      total: total,
                      trialEndsAt: trialEnds,
                      chargeStartsAt: chargeStarts,
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  // Secondary CTA: cho user "Để sau" → về dashboard, không
                  // ép phải tạo homestay ngay lập tức.
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.borderDefault),
                        foregroundColor: colors.textSecondary,
                      ),
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Để sau · Về trang chủ'),
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 320.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final DateTime trialEndsAt;
  const _SuccessBanner({required this.trialEndsAt});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.successBg,
        border: Border(
          bottom: BorderSide(color: colors.success.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check, size: 20, color: colors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tài khoản đã được duyệt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trial 7 ngày bắt đầu từ hôm nay · Đến ${VerifyFormat.dateVN(trialEndsAt)}',
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
      ),
    );
  }
}

class _StartHereCard extends StatelessWidget {
  static const _bullets = [
    'Thông tin cơ bản',
    'Địa chỉ + Vị trí trên map',
    'Hình ảnh + Tiện nghi',
    'Chính sách + Giá phòng',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BẮT ĐẦU TỪ ĐÂY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Đăng phòng đầu tiên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thiết lập homestay với 8 bước · Khoảng 10 phút.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),
          ..._bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check, size: 14, color: colors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => context.go('/properties/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo homestay đầu tiên'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Plan plan;
  final BillingCycle cycle;
  final int total;
  final DateTime trialEndsAt;
  final DateTime chargeStartsAt;

  const _SubscriptionCard({
    required this.plan,
    required this.cycle,
    required this.total,
    required this.trialEndsAt,
    required this.chargeStartsAt,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = trialEndsAt.difference(DateTime.now());
    final isUnder24h = remaining.inHours < 24;

    return InkWell(
      onTap: () {
        context.push('/verify/subscription-detail');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border.all(color: colors.borderDefault),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GÓI CỦA BẠN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: colors.textTertiary,
                  ),
                ),
                _TrialBadge(
                  trialEndsAt: trialEndsAt,
                  isUrgent: isUnder24h,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${plan.tier.displayName} · ${cycle == BillingCycle.yearly ? "Hàng năm" : "Hàng tháng"}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${VerifyFormat.priceVND(total)}/${cycle == BillingCycle.yearly ? "năm" : "tháng"} · Tự động gia hạn',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: colors.borderSubtle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateBlock(
                    label: 'DÙNG TRIAL ĐẾN',
                    value: VerifyFormat.dateVN(trialEndsAt),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: colors.borderSubtle,
                ),
                Expanded(
                  child: _DateBlock(
                    label: 'CHARGE TỪ',
                    value: VerifyFormat.dateVN(chargeStartsAt),
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

class _TrialBadge extends StatelessWidget {
  final DateTime trialEndsAt;
  final bool isUrgent;

  const _TrialBadge({required this.trialEndsAt, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = isUrgent ? colors.warning : colors.brandSecondary;
    final bg = (isUrgent ? colors.warning : colors.brandSecondary)
        .withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TrialCountdownText(
        trialEndsAt: trialEndsAt,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String label;
  final String value;
  const _DateBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
