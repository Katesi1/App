import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_quote.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import '../../../shared/widgets/app_toast.dart';
import '../utils/payment_error_handler.dart';
import 'widgets/plan_card.dart';
import 'widgets/verify_app_bar.dart';
import 'widgets/verify_format.dart';

/// Screen 4 — Chọn gói subscription.
///
/// 6 tier theo số phòng cố định: Mini (1) / Starter (5) / Standard (10) /
/// Pro (20) / Business (50) / Enterprise (unlimited — Liên hệ).
/// User pick tier xong → số phòng = `tier.rooms`, không tự nhập.
/// Toggle Monthly/Yearly áp dụng cho 5 tier có giá cố định; Enterprise
/// bypass toggle, tap → /profile/help liên hệ.
class SelectPlanScreen extends ConsumerStatefulWidget {
  final bool isUpgrade;

  const SelectPlanScreen({super.key, this.isUpgrade = false});

  @override
  ConsumerState<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends ConsumerState<SelectPlanScreen> {
  late BillingCycle _cycle;
  Tier? _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final verifyState = ref.read(verifyFlowControllerProvider);
    final user = ref.read(currentUserProvider);
    _cycle = _initialCycle(verifyState.billingCycle, user?.subscriptionCycle);
    _selected = verifyState.selectedPlan?.tier ??
        Plan.tierFromPlanId(user?.subscriptionPlanId) ??
        Tier.rooms5;
  }

  BillingCycle _initialCycle(BillingCycle draft, String? userCycle) {
    if (userCycle == 'monthly') return BillingCycle.monthly;
    if (userCycle == 'yearly') return BillingCycle.yearly;
    return draft;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plansAsync = ref.watch(verifyPlansProvider);
    final isUpgrade = widget.isUpgrade;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: VerifyAppBar(
        overline: isUpgrade ? 'NÂNG CẤP GÓI' : 'BƯỚC 1/2 · MUA GÓI',
        title: isUpgrade ? 'Chọn gói mới' : 'Chọn gói phù hợp',
        currentStep: 1,
        totalSteps: 2,
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (plans) {
          final selectedPlan = PlanPriceCalculator.planFor(_selected!, plans);
          if (selectedPlan == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!selectedPlan.hasFixedPrice) {
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    120,
                  ),
                  children: [
                    _BillingToggle(
                      cycle: _cycle,
                      onChanged: (c) => setState(() => _cycle = c),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...plans.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: PlanCard(
                              plan: e.value,
                              cycle: _cycle,
                              isSelected: e.value.tier == _selected,
                              onTap: () => _onPlanTap(e.value),
                            ),
                          ),
                        ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _CTABar(
                    planName: selectedPlan.tier.displayName,
                    totalLabel: 'Liên hệ tư vấn',
                    label: 'Tư vấn Enterprise',
                    onTap: () => context.push('/profile/help'),
                  ),
                ),
              ],
            );
          }

          final quoteParams = (
            planId: selectedPlan.id,
            cycle: _cycle,
            rooms: selectedPlan.rooms,
          );
          final quoteAsync = ref.watch(paymentQuoteProvider(quoteParams));

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  120,
                ),
                children: [
                  _BillingToggle(
                    cycle: _cycle,
                    onChanged: (c) => setState(() => _cycle = c),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...plans.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PlanCard(
                            plan: e.value,
                            cycle: _cycle,
                            isSelected: e.value.tier == _selected,
                            onTap: () => _onPlanTap(e.value),
                          )
                              .animate(delay: (60 * e.key).ms)
                              .fadeIn(duration: 280.ms)
                              .slideY(begin: 0.08, end: 0),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  _TrialBanner(),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: quoteAsync.when(
                  loading: () => _CTABar(
                    planName: selectedPlan.tier.displayName,
                    totalLabel: 'Đang tính giá...',
                    label: isUpgrade ? 'Nâng cấp' : 'Tiếp tục',
                    enabled: false,
                    onTap: () {},
                  ),
                  error: (e, _) {
                    final apiEx = e is VerifyApiException ? e : null;
                    final frozen = apiEx?.isSubscriptionFrozen == true;
                    return _CTABar(
                      planName: selectedPlan.tier.displayName,
                      totalLabel: frozen
                          ? 'Tài khoản bị đóng băng'
                          : 'Không tải được giá · Chạm thử lại',
                      label: isUpgrade ? 'Nâng cấp' : 'Tiếp tục',
                      enabled: !frozen,
                      onTap: () {
                        if (frozen && apiEx != null) {
                          showPaymentApiError(context, apiEx);
                          return;
                        }
                        ref.invalidate(paymentQuoteProvider(quoteParams));
                      },
                    );
                  },
                  data: (quote) => _CTABar(
                    planName: selectedPlan.tier.displayName,
                    totalLabel: quote.isDowngrade
                        ? 'Áp dụng từ ${VerifyFormat.dateVN(quote.effectiveAt ?? DateTime.now())}'
                        : '${VerifyFormat.priceVND(quote.totalAmount)}'
                            '${quote.isCatalogFallback ? ' (tạm tính)' : ''}',
                    label: quote.isDowngrade
                        ? 'Đặt lịch hạ gói'
                        : (isUpgrade ? 'Nâng cấp' : 'Tiếp tục'),
                    enabled: !_submitting,
                    loading: _submitting,
                    onTap: () => _onContinue(selectedPlan, quote),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onPlanTap(Plan plan) {
    setState(() => _selected = plan.tier);
  }

  Future<void> _onContinue(Plan plan, PaymentQuote quote) async {
    setState(() => _submitting = true);
    final notifier = ref.read(verifyFlowControllerProvider.notifier);
    notifier.selectPlan(plan, _cycle, quote: quote);

    if (quote.isDowngrade) {
      try {
        await notifier.initiatePayment(PaymentMethod.bankTransfer);
      } on VerifyApiException catch (e) {
        if (!mounted) return;
        if (e.isDowngradeScheduled) {
          await ref.read(authProvider.notifier).refreshProfile();
          if (!mounted) return;
          showPaymentApiError(context, e);
          context.go('/verify/subscription-detail');
        } else {
          showPaymentApiError(context, e);
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _submitting = false);
      context.push('/verify/payment');
    }
  }
}

class _BillingToggle extends StatelessWidget {
  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;

  const _BillingToggle({required this.cycle, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: 'Hàng tháng',
              isActive: cycle == BillingCycle.monthly,
              onTap: () => onChanged(BillingCycle.monthly),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Hàng năm',
              isActive: cycle == BillingCycle.yearly,
              onTap: () => onChanged(BillingCycle.yearly),
              badge: '−20%',
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _ToggleSegment({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? colors.bgSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: isActive ? Border.all(color: colors.borderDefault) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? colors.textPrimary : colors.textTertiary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.goldBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colors.brandSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successBgDark,
        border: Border.all(color: AppColors.successBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 18, color: colors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7 NGÀY DÙNG THỬ MIỄN PHÍ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: colors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trial bắt đầu sau khi admin duyệt — không tính tiền lúc trial.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    height: 1.4,
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

class _CTABar extends StatelessWidget {
  final String planName;
  final String totalLabel;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;

  const _CTABar({
    required this.planName,
    required this.totalLabel,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: enabled && !loading ? onTap : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '$label $planName · $totalLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
