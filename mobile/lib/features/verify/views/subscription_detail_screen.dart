import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_strip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import '../data/models/verify_state.dart';
import '../utils/payment_close_confirm.dart';
import '../utils/payment_awaiting_handler.dart';
import '../utils/payment_status_poller.dart';
import 'widgets/payment_dialogs.dart';
import 'widgets/status_timeline.dart';
import 'widgets/subscription_hero_card.dart';
import 'widgets/verify_format.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({super.key});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen>
    with WidgetsBindingObserver {
  bool _renewing = false;
  bool _awaitingReconcile = false;
  bool _bootstrapping = true;
  PaymentStatusPoller? _poller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      ref.read(authProvider.notifier).refreshProfile(),
      ref.read(verifyFlowControllerProvider.notifier).hydrate(),
    ]);
    if (mounted) setState(() => _bootstrapping = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling(clearFcm: true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _poller?.pause();
      return;
    }
    if (state == AppLifecycleState.resumed && _poller?.isRunning == true) {
      _poller?.resume();
    }
  }

  Future<void> _handleRenew() async {
    final method = await showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: context.colors.bgSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _RenewMethodSheet(),
    );
    if (method == null || !mounted) return;

    setState(() => _renewing = true);
    try {
      final session = await ref
          .read(verifyFlowControllerProvider.notifier)
          .initiateRenewal(method);
      if (!mounted) return;
      _openSessionDialog(session, method);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tạo phiên gia hạn thất bại: '
            '${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted && !_awaitingReconcile) {
        setState(() => _renewing = false);
      }
    }
  }

  void _openSessionDialog(PaymentSession session, PaymentMethod method) {
    if (method == PaymentMethod.bankTransfer) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BankTransferDialog(
          session: session,
          onWaitAndClose: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Đã ghi nhận. Bạn sẽ nhận thông báo khi thanh toán '
                  'được xác nhận.',
                ),
                backgroundColor: context.colors.brand,
              ),
            );
          },
        ),
      );
      setState(() => _awaitingReconcile = true);
      _startPolling(session.expiresAt);
    }
  }

  void _startPolling(DateTime expiresAt) {
    _stopPolling(clearFcm: false);
    PushNotificationService.instance.onForegroundData = (data) {
      if (!isPaymentPaidPush(data)) return;
      _poller?.checkNow();
    };

    _poller = PaymentStatusPoller(
      expiresAt: expiresAt,
      onPoll: _pollOnce,
      onExpired: () {
        if (!mounted) return;
        setState(() {
          _renewing = false;
          _awaitingReconcile = false;
        });
        _stopPolling(clearFcm: true);
      },
    );
    _poller!.start();
  }

  Future<void> _pollOnce() async {
    try {
      final status = await ref
          .read(verifyFlowControllerProvider.notifier)
          .checkPaymentStatus();
      if (!mounted) return;
      final handled = await handlePaymentStatusUpdate(
        status: status,
        context: context,
        ref: ref,
        onPollingStopped: () => _stopPolling(clearFcm: true),
        setProcessing: (v) => setState(() {
          _renewing = v;
          _awaitingReconcile = v;
        }),
        successRoute: '/verify/subscription-detail',
        popDialog: true,
      );
      if (handled && status == PaymentStatus.paid && mounted) {
        ref.invalidate(paymentHistoryProvider);
        ref.invalidate(paymentHistoryListProvider);
      }
    } catch (_) {}
  }

  void _stopPolling({required bool clearFcm}) {
    _poller?.stop();
    _poller = null;
    if (clearFcm) {
      PushNotificationService.instance.onForegroundData = null;
    }
  }

  Future<void> _handleBackWhilePending() async {
    if (!_awaitingReconcile) {
      if (context.canPop()) context.pop();
      return;
    }

    final confirmed = await confirmClosePendingPayment(
      context,
      isBankTransfer: true,
    );
    if (!confirmed || !mounted) return;

    _stopPolling(clearFcm: true);
    setState(() {
      _renewing = false;
      _awaitingReconcile = false;
    });
    if (context.canPop()) context.pop();
  }

  BillingCycle _resolveCycle(
    VerifyFlowState state,
    String? userCycle,
  ) {
    if (userCycle == 'monthly') return BillingCycle.monthly;
    if (userCycle == 'yearly') return BillingCycle.yearly;
    return state.billingCycle;
  }

  String _cycleLabel(BillingCycle cycle) =>
      cycle == BillingCycle.yearly ? 'Hàng năm' : 'Hàng tháng';

  List<TimelineStep> _timelineSteps(UserModel user) {
    if (user.isInTrial) {
      return [
        TimelineStep(
          title: 'Đăng ký gói',
          subtitle: user.subscriptionPlanLabel,
          status: TimelineStepStatus.done,
        ),
        TimelineStep(
          title: 'Đang dùng thử',
          subtitle: user.trialEndsAt != null
              ? 'Đến ${VerifyFormat.dateVN(user.trialEndsAt!)}'
              : 'Miễn phí 7 ngày',
          status: TimelineStepStatus.current,
        ),
        TimelineStep(
          title: 'Thu phí đầu tiên',
          subtitle: user.nextChargeAt != null
              ? VerifyFormat.dateVN(user.nextChargeAt!)
              : 'Sau khi trial kết thúc',
          status: TimelineStepStatus.pending,
        ),
      ];
    }

    if (user.isSubscriptionActive) {
      return [
        const TimelineStep(
          title: 'KYC & thanh toán',
          subtitle: 'Đã hoàn tất',
          status: TimelineStepStatus.done,
        ),
        TimelineStep(
          title: 'Gói đang hoạt động',
          subtitle: user.subscriptionPlanLabel,
          status: TimelineStepStatus.current,
        ),
        TimelineStep(
          title: 'Gia hạn tiếp theo',
          subtitle: user.nextChargeAt != null
              ? VerifyFormat.dateVN(user.nextChargeAt!)
              : 'Theo chu kỳ đã chọn',
          status: TimelineStepStatus.pending,
        ),
      ];
    }

    if (user.isSubscriptionPastDue) {
      return [
        const TimelineStep(
          title: 'Gói trước đó',
          subtitle: 'Đã kích hoạt',
          status: TimelineStepStatus.done,
        ),
        const TimelineStep(
          title: 'Quá hạn thanh toán',
          subtitle: 'Vui lòng gia hạn để tiếp tục',
          status: TimelineStepStatus.current,
        ),
        const TimelineStep(
          title: 'Khôi phục dịch vụ',
          subtitle: 'Sau khi thanh toán thành công',
          status: TimelineStepStatus.pending,
        ),
      ];
    }

    if (user.isSubscriptionCancelled) {
      return [
        const TimelineStep(
          title: 'Đã huỷ gói',
          subtitle: 'Subscription không còn hiệu lực',
          status: TimelineStepStatus.current,
        ),
        const TimelineStep(
          title: 'Mua lại gói',
          subtitle: 'Chọn gói mới để tiếp tục quản lý',
          status: TimelineStepStatus.pending,
        ),
      ];
    }

    return const [
      TimelineStep(
        title: 'Chưa kích hoạt',
        subtitle: 'Chọn gói để bắt đầu',
        status: TimelineStepStatus.current,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authProvider);
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(verifyFlowControllerProvider);
    final plansAsync = ref.watch(verifyPlansProvider);

    if (_bootstrapping && user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết gói đăng ký')),
        body: const DetailSkeleton(),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết gói đăng ký')),
        body: ErrorStateWidget(
          message: 'Không tải được thông tin tài khoản',
          onRetry: _bootstrap,
        ),
      );
    }

    final tier = Plan.tierFromPlanId(user.subscriptionPlanId);
    final catalogPlan = plansAsync.maybeWhen(
      data: (plans) =>
          tier != null ? PlanPriceCalculator.planFor(tier, plans) : null,
      orElse: () => null,
    );
    final plan = catalogPlan ?? state.selectedPlan;
    final cycle = _resolveCycle(state, user.subscriptionCycle);
    final total = plan == null ? 0 : PlanPriceCalculator.total(plan, cycle);
    final canRenew = user.isInTrial ||
        user.isSubscriptionActive ||
        user.isSubscriptionPastDue;
    final planActionLabel = user.subscriptionPlanActionLabel;
    final planActionRoute = user.subscriptionPlanPickerRoute;
    final planActionIcon = user.hasEverPurchasedSubscription
        ? Icons.upgrade
        : Icons.shopping_cart_outlined;
    final timeline = _timelineSteps(user);
    final metrics = _buildMetrics(user, plan, cycle, total);

    return PopScope(
      canPop: !_awaitingReconcile,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackWhilePending();
      },
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          title: const Text('Chi tiết gói đăng ký'),
          leading: BackButton(onPressed: _handleBackWhilePending),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                if (_awaitingReconcile) ...[
                  const StatusStrip(
                    icon: Icons.schedule,
                    label: 'Đang chờ đối soát thủ công',
                    subtitle: 'Có thể mất 1–3 giờ. Bạn có thể đóng app — '
                        'sẽ nhận thông báo khi xác nhận thành công.',
                    variant: StatusStripVariant.brand,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SubscriptionHeroCard(
                  user: user,
                  plan: plan,
                  billingCycle: cycle,
                  totalPrice: total,
                ),
                const SizedBox(height: AppSpacing.md),
                _sectionEntrance(
                  index: 0,
                  child: _SectionHeader(
                    title: 'Thông tin nhanh',
                    subtitle: user.subscriptionMenuSubtitle,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _sectionEntrance(
                  index: 1,
                  child: _MetricsGrid(metrics: metrics),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionEntrance(
                  index: 2,
                  child: const _SectionHeader(
                    title: 'Tiến trình gói',
                    subtitle: 'Các mốc quan trọng của subscription',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _sectionEntrance(
                  index: 3,
                  child: StatusTimeline(steps: timeline),
                ),
                if (plan != null && plan.features.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionEntrance(
                    index: 4,
                    child: _FeaturesSection(plan: plan),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _sectionEntrance(
                  index: 5,
                  child: _ActionsSection(
                    planActionLabel: planActionLabel,
                    planActionRoute: planActionRoute,
                    planActionIcon: planActionIcon,
                    canRenew: canRenew,
                    renewing: _renewing,
                    plan: plan,
                    total: total,
                    onRenew: _handleRenew,
                  ),
                ),
              ],
            ),
            if (authState.isLoading || plansAsync.isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: colors.brand,
                  backgroundColor: colors.borderSubtle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<({IconData icon, Color color, String label, String value})>
      _buildMetrics(
    UserModel user,
    Plan? plan,
    BillingCycle cycle,
    int total,
  ) {
    final items = <({IconData icon, Color color, String label, String value})>[
      (
        icon: Icons.calendar_month_outlined,
        color: AppColors.jade300,
        label: 'Chu kỳ',
        value: _cycleLabel(cycle),
      ),
      (
        icon: Icons.payments_outlined,
        color: AppColors.jade300,
        label: 'Chi phí',
        value: plan == null
            ? '—'
            : (plan.hasFixedPrice ? VerifyFormat.priceVND(total) : 'Liên hệ'),
      ),
    ];

    if (user.trialEndsAt != null) {
      items.add((
        icon: Icons.hourglass_empty_outlined,
        color: AppColors.gold500,
        label: 'Trial đến',
        value: VerifyFormat.dateVN(user.trialEndsAt!),
      ));
    }

    if (user.nextChargeAt != null) {
      items.add((
        icon: Icons.event_repeat_outlined,
        color: AppColors.success,
        label: 'Thu phí tiếp',
        value: VerifyFormat.dateVN(user.nextChargeAt!),
      ));
    }

    return items;
  }
}

Widget _sectionEntrance({required int index, required Widget child}) {
  if (index > 4) return child;
  return child
      .animate(delay: (120 + index * 70).ms)
      .fadeIn(duration: 280.ms)
      .slideY(begin: 0.05, end: 0, duration: 280.ms);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<({IconData icon, Color color, String label, String value})>
      metrics;

  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.45,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) {
        final m = metrics[i];
        return SubscriptionMetricTile(
          icon: m.icon,
          iconColor: m.color,
          label: m.label,
          value: m.value,
        );
      },
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  final Plan plan;

  const _FeaturesSection({required this.plan});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Quyền lợi gói',
          subtitle: plan.tier.tagline,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Column(
            children: plan.features.map((f) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: colors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final String planActionLabel;
  final String planActionRoute;
  final IconData planActionIcon;
  final bool canRenew;
  final bool renewing;
  final Plan? plan;
  final int total;
  final VoidCallback onRenew;

  const _ActionsSection({
    required this.planActionLabel,
    required this.planActionRoute,
    required this.planActionIcon,
    required this.canRenew,
    required this.renewing,
    required this.plan,
    required this.total,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Thao tác',
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () => context.push(planActionRoute),
            icon: Icon(planActionIcon, size: 18),
            label: Text(planActionLabel),
          ),
        ),
        if (canRenew) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            child: FilledButton.tonalIcon(
              onPressed: renewing || plan == null ? null : onRenew,
              icon: renewing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.brand,
                      ),
                    )
                  : const Icon(Icons.autorenew, size: 18),
              label: Text(
                renewing
                    ? 'Đang tạo phiên...'
                    : 'Gia hạn ngay (${VerifyFormat.priceVND(total)})',
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/verify/payment-history'),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Lịch sử thanh toán'),
          ),
        ),
      ],
    );
  }
}

class _RenewMethodSheet extends StatelessWidget {
  const _RenewMethodSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn phương thức gia hạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hệ thống dùng plan + chu kỳ hiện tại của bạn.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MethodOption(
            icon: Icons.account_balance,
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'Quét QR + STK · Đối soát thủ công 1–3 giờ',
            onTap: () => Navigator.of(context).pop(PaymentMethod.bankTransfer),
          ),
          const SizedBox(height: 8),
          _MethodOption(
            icon: Icons.credit_card,
            title: 'Thẻ tín dụng / Ghi nợ',
            subtitle: 'Visa, Mastercard, JCB',
            locked: true,
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool locked;

  const _MethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border.all(color: colors.borderDefault),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: colors.brandLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: colors.textTertiary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      locked ? 'Sắp ra mắt trong bản cập nhật tới' : subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!locked)
                Icon(Icons.chevron_right, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
