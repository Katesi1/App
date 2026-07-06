import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import '../data/repositories/verify_repository_impl.dart';
import 'widgets/plan_card.dart';
import 'widgets/verify_app_bar.dart';
import 'widgets/verify_format.dart';

/// Screen 4 — pick subscription plan.
///
/// 6 tiers with fixed room counts: Mini (1) / Starter (5) / Standard (10) /
/// Pro (20) / Business (50) / Enterprise (unlimited — contact us).
/// Once the user picks a tier, room count = `tier.rooms` — not user-entered.
/// Monthly/Yearly toggle applies to the 5 fixed-price tiers; Enterprise
/// bypasses the toggle, tap → /profile/help to contact sales.
class SelectPlanScreen extends ConsumerStatefulWidget {
  const SelectPlanScreen({super.key});

  @override
  ConsumerState<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends ConsumerState<SelectPlanScreen> {
  late BillingCycle _cycle;
  Tier? _selected;

  // Giá hiển thị = số tiền BE chốt (`POST /payments/quote`), KHÔNG tự tính local.
  Timer? _debounce;
  PaymentQuote? _quote;
  bool _quoting = false;
  String? _quoteError;
  String _lastKey = '';

  @override
  void initState() {
    super.initState();
    final state = ref.read(verifyFlowControllerProvider);
    _cycle = state.billingCycle;
    // Default Starter (5 rooms) — most common tier for small homestays.
    _selected = state.selectedPlan?.tier ?? Tier.rooms5;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Gọi quote (debounce) khi user đổi plan/cycle. Enterprise (giá liên hệ) thì
  /// bỏ qua.
  void _maybeQuote(Plan plan) {
    if (plan.isEnterprise) {
      if (_quote != null || _quoting || _quoteError != null) {
        setState(() {
          _quote = null;
          _quoting = false;
          _quoteError = null;
        });
      }
      _lastKey = 'enterprise';
      return;
    }
    final key = '${plan.tier}_${_cycle.name}';
    if (key == _lastKey) return;
    _lastKey = key;
    _debounce?.cancel();
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _runQuote(plan, _cycle, key),
    );
  }

  Future<void> _runQuote(Plan plan, BillingCycle cycle, String key) async {
    try {
      final q = await ref
          .read(verifyFlowControllerProvider.notifier)
          .getQuoteFor(plan, cycle);
      if (!mounted || key != _lastKey) return;
      setState(() {
        _quote = q;
        _quoting = false;
      });
    } on VerifyApiException catch (e) {
      if (!mounted || key != _lastKey) return;
      setState(() {
        _quoting = false;
        _quote = null;
        _quoteError = e.message;
      });
    } catch (e) {
      if (!mounted || key != _lastKey) return;
      setState(() {
        _quoting = false;
        _quote = null;
        _quoteError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plansAsync = ref.watch(verifyPlansProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: const VerifyAppBar(
        overline: 'NÂNG GÓI · SUBSCRIPTION',
        title: 'Chọn gói phù hợp',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(verifyPlansProvider);
          await ref.read(verifyPlansProvider.future);
        },
        child: plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (plans) {
            final selectedPlan = PlanPriceCalculator.planFor(_selected!, plans);
            // Quote lại khi selection/cycle đổi (sau frame để tránh setState lúc build).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _maybeQuote(selectedPlan);
            });

            return Stack(
              children: [
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                  child: _CTABar(
                    planName: selectedPlan.tier.displayName,
                    isEnterprise: selectedPlan.isEnterprise,
                    quoting: _quoting,
                    quoteError: _quoteError,
                    total: _quote?.totalAmount,
                    kind: _quote?.kind,
                    onTap: () {
                      if (selectedPlan.isEnterprise) {
                        context.push('/profile/help');
                        return;
                      }
                      if (_quoteError != null) {
                        _maybeQuote(selectedPlan); // retry
                        return;
                      }
                      ref
                          .read(verifyFlowControllerProvider.notifier)
                          .selectPlan(selectedPlan, _cycle);
                      context.push('/verify/payment');
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onPlanTap(Plan plan) {
    setState(() => _selected = plan.tier);
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
        // Theme-aware success tint (mint in light, deep green in dark) instead
        // of the hardcoded dark token — harmonious on the light plan canvas.
        color: colors.successBg,
        border: Border.all(color: colors.success.withValues(alpha: 0.25)),
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
  final bool isEnterprise;
  final bool quoting;
  final String? quoteError;

  /// Số tiền BE chốt (quote). null khi đang tính / lỗi / enterprise.
  final int? total;
  final TransactionKind? kind;
  final VoidCallback onTap;

  const _CTABar({
    required this.planName,
    required this.isEnterprise,
    required this.quoting,
    required this.quoteError,
    required this.total,
    required this.kind,
    required this.onTap,
  });

  String _label() {
    if (isEnterprise) return 'Liên hệ tư vấn';
    if (quoteError != null) return 'Thử lại';
    if (quoting || total == null) return 'Đang tính giá...';
    final action = kind == TransactionKind.upgrade
        ? 'Nâng lên'
        : kind == TransactionKind.downgrade
            ? 'Hạ xuống'
            : 'Chọn';
    return '$action $planName · ${VerifyFormat.priceVND(total!)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showSpinner = quoting && !isEnterprise && quoteError == null;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quoteError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                quoteError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: colors.error),
              ),
            ),
          SizedBox(
            height: 52,
            child: FilledButton(
              // Chặn bấm khi đang tính giá (chưa có số tiền thật từ BE).
              onPressed: showSpinner ? null : onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showSpinner) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.darkBg),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _label(),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (!showSpinner && !isEnterprise && quoteError == null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
