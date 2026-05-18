import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/monitoring/analytics_service.dart';
import '../../../shared/widgets/status_strip.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/payment_dialogs.dart';
import 'widgets/payment_method_tile.dart';
import 'widgets/verify_app_bar.dart';
import 'widgets/verify_format.dart';

/// 3 payment methods exposed by FE:
/// - VNPay QR: scan QR with bank app (instant)
/// - Bank transfer: account number + memo (5-30 min, Casso/Sepay reconcile)
/// - Card: Visa/Mastercard/JCB via VNPay (instant)
///
/// BE must accept all 3 methods at `POST /payments/initiate`. If BE hasn't
/// enabled `card` yet, FE catches the error and shows a graceful message.
const _kAvailableMethods = <PaymentMethod>[
  PaymentMethod.vnpayQR,
  PaymentMethod.bankTransfer,
  PaymentMethod.card,
];

/// Screen 5 — Payment.
///
/// Flow:
/// 1. User selects method → taps CTA
/// 2. Controller creates payment session
/// 3. Show method-specific dialog (QR / bank info / card form)
/// 4. Poll status every 3s, max 5 minutes (100 calls)
/// 5. On paid → controller auto-submitForApproval → push pending screen
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selected = PaymentMethod.vnpayQR;
  bool _processing = false;
  Timer? _pollTimer;
  int _pollCount = 0;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _handlePay() async {
    AnalyticsService.logEvent('verify_payment_submit', params: {
      'method': _selected.name,
    });
    setState(() => _processing = true);
    try {
      final session = await ref
          .read(verifyFlowControllerProvider.notifier)
          .initiatePayment(_selected);
      AnalyticsService.logEvent('verify_payment_session_created', params: {
        'method': _selected.name,
        'amount': session.totalAmount,
      });

      if (!mounted) return;

      // Open the dialog matching the method. Card is locked in UI so not handled.
      switch (_selected) {
        case PaymentMethod.vnpayQR:
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => VNPayQRDialog(session: session),
          );
          break;
        case PaymentMethod.bankTransfer:
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (_) => BankTransferDialog(session: session),
          );
          break;
        case PaymentMethod.card:
          // Unreachable: card is disabled in UI.
          break;
      }
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      _showError('Khởi tạo thanh toán thất bại: $msg');
      AnalyticsService.logEvent('verify_payment_session_failed', params: {
        'method': _selected.name,
      });
      setState(() => _processing = false);
    }
  }

  /// Max poll count per method:
  /// - VNPay QR: 20 polls × 3s = 60s. VNPay IPN usually returns ~3-5s after
  ///   payment (spec §7.5). > 60s without paid → likely backend/IPN config
  ///   issue → fallback "Contact support" rather than make the user wait forever.
  /// - Bank transfer: 600 polls × 3s = 30 minutes. Casso/Sepay reconciliation
  ///   is 5-30 min (spec §5.2). > 30 minutes → user can close app, webhook
  ///   handles it.
  int get _maxPollCount => switch (_selected) {
        PaymentMethod.vnpayQR => 20, // 60s
        PaymentMethod.bankTransfer => 600, // 30 min
        PaymentMethod.card => 20,
      };

  void _startPolling() {
    _pollTimer?.cancel();
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      if (_pollCount > _maxPollCount) {
        timer.cancel();
        if (mounted) {
          setState(() => _processing = false);
          if (_selected == PaymentMethod.bankTransfer) {
            // Bank transfer: not a failure — user can close the app and the
            // system will auto-confirm when the bank webhook fires. Show info.
            _showInfo(
              'Vẫn đang đối soát chuyển khoản. Bạn có thể đóng app — '
              'hệ thống sẽ tự xác nhận khi nhận được tiền.',
            );
          } else {
            // VNPay: > 60s is abnormal. Direct user to support.
            _showError(
              'Chưa nhận được xác nhận từ VNPay sau 60 giây. '
              'Nếu bạn đã thanh toán, vui lòng liên hệ hỗ trợ.',
            );
          }
        }
        return;
      }
      try {
        final status = await ref
            .read(verifyFlowControllerProvider.notifier)
            .checkPaymentStatus();
        if (status == PaymentStatus.paid) {
          timer.cancel();
          if (!mounted) return;
          // Close any open dialog.
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          context.pushReplacement('/verify/pending');
        } else if (status == PaymentStatus.failed ||
            status == PaymentStatus.expired) {
          timer.cancel();
          if (mounted) {
            setState(() => _processing = false);
            _showError('Thanh toán thất bại');
          }
        }
      } catch (_) {
        // silent retry — exponential backoff unnecessary for our use case
      }
    });
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 4),
        backgroundColor: context.colors.brand,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.colors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final plan = state.selectedPlan;

    if (plan == null) {
      return Scaffold(
        appBar: const VerifyAppBar(
          overline: 'BƯỚC 6/7 · SUBSCRIPTION',
          title: 'Thanh toán',
        ),
        body:
            const Center(child: Text('Chưa chọn plan — quay lại bước trước.')),
      );
    }

    final total = PlanPriceCalculator.total(plan, state.billingCycle);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: const VerifyAppBar(
        overline: 'BƯỚC 6/7 · SUBSCRIPTION',
        title: 'Thanh toán',
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              120,
            ),
            children: [
              OrderSummaryCard(
                plan: plan,
                cycle: state.billingCycle,
              ).animate().fadeIn(duration: 320.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                'PHƯƠNG THỨC THANH TOÁN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              ...PaymentMethod.values.asMap().entries.map((e) {
                final method = e.value;
                final isAvailable = _kAvailableMethods.contains(method);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PaymentMethodTile(
                    method: method,
                    isSelected: _selected == method,
                    isComingSoon: !isAvailable,
                    onTap: () {
                      if (!isAvailable) return;
                      setState(() => _selected = method);
                    },
                  )
                      .animate(delay: (60 * e.key).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: 0.05, end: 0),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              const StatusStrip(
                icon: Icons.lock_outline,
                label: 'Hoàn tiền 100% trong 14 ngày',
                subtitle:
                    'Nếu không hài lòng, yêu cầu hoàn tiền trong vòng 14 ngày kể từ thanh toán.',
                variant: StatusStripVariant.brand,
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                child: FilledButton.icon(
                  onPressed: _processing ? null : _handlePay,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.darkBg),
                        )
                      : const Icon(Icons.lock_outline, size: 18),
                  label: Text(
                    _processing
                        ? 'Đang xử lý...'
                        : 'Thanh toán an toàn ${VerifyFormat.priceVND(total)}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
