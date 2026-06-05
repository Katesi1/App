import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/status_strip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import '../utils/payment_awaiting_handler.dart';
import '../utils/payment_status_poller.dart';
import 'widgets/payment_dialogs.dart';
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
  PaymentStatusPoller? _poller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
          content: Text('Tạo phiên gia hạn thất bại: '
              '${e.toString().replaceAll('Exception: ', '')}'),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final user = ref.watch(currentUserProvider);
    final plan = state.selectedPlan;
    final planLabel =
        plan?.tier.displayName ?? user?.subscriptionPlanLabel ?? 'Chưa có';
    final cycleLabel = _cycleLabel(state.billingCycle, user?.subscriptionCycle);
    final total =
        plan == null ? 0 : PlanPriceCalculator.total(plan, state.billingCycle);
    final canRenew = user != null &&
        (user.isInTrial ||
            user.isSubscriptionActive ||
            user.isSubscriptionPastDue);
    final planActionLabel = user?.subscriptionPlanActionLabel ?? 'Mua gói';
    final planActionRoute =
        user?.subscriptionPlanPickerRoute ?? '/verify/select-plan';
    final planActionIcon = user?.hasEverPurchasedSubscription == true
        ? Icons.upgrade
        : Icons.shopping_cart_outlined;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết gói đăng ký')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_awaitingReconcile) ...[
            const StatusStrip(
              icon: Icons.schedule,
              label: 'Đang chờ đối soát thủ công',
              subtitle: 'Có thể mất 1–3 giờ. Bạn có thể đóng app — sẽ nhận '
                  'thông báo khi xác nhận thành công.',
              variant: StatusStripVariant.brand,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
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
            value: planLabel,
          ),
          _DetailItem(
            label: 'Chu kỳ',
            value: cycleLabel,
          ),
          if (plan != null)
            _DetailItem(
              label: 'Chi phí',
              value: VerifyFormat.priceVND(total),
            ),
          if (user?.trialEndsAt != null)
            _DetailItem(
              label: 'Trial đến',
              value: VerifyFormat.dateVN(user!.trialEndsAt!),
            ),
          if (user?.nextChargeAt != null)
            _DetailItem(
              label: 'Thu phí tiếp',
              value: VerifyFormat.dateVN(user!.nextChargeAt!),
            ),
          const SizedBox(height: AppSpacing.lg),
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
              child: FilledButton.icon(
                onPressed: _renewing || plan == null ? null : _handleRenew,
                icon: _renewing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew, size: 18),
                label: Text(
                  _renewing
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
      ),
    );
  }

  String _cycleLabel(BillingCycle draft, String? userCycle) {
    if (userCycle == 'monthly') return 'Hàng tháng';
    if (userCycle == 'yearly') return 'Hàng năm';
    return draft == BillingCycle.yearly ? 'Hàng năm' : 'Hàng tháng';
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

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
