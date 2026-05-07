import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import 'widgets/verify_format.dart';

class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final plan = state.selectedPlan;
    final total =
        plan == null ? 0 : PlanPriceCalculator.total(plan, state.billingCycle);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết gói đăng ký')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'Thông tin gói hiện tại, chu kỳ thanh toán và các mốc trial.',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailItem(
            label: 'Tên gói',
            value: plan?.tier.displayName ?? 'Chưa chọn',
          ),
          _DetailItem(
            label: 'Chu kỳ',
            value: state.billingCycle == BillingCycle.yearly
                ? 'Hàng năm'
                : 'Hàng tháng',
          ),
          _DetailItem(
            label: 'Chi phí',
            value: VerifyFormat.priceVND(total),
          ),
          if (state.trialEndsAt != null)
            _DetailItem(
              label: 'Trial đến',
              value: VerifyFormat.dateVN(state.trialEndsAt!),
            ),
          if (state.chargeStartsAt != null)
            _DetailItem(
              label: 'Bắt đầu thu phí',
              value: VerifyFormat.dateVN(state.chargeStartsAt!),
            ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
