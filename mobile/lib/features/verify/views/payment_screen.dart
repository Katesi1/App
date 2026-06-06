import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/monitoring/analytics_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/status_strip.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import '../data/models/verify_enums.dart';
import '../utils/payment_close_confirm.dart';
import '../utils/payment_error_handler.dart';
import '../utils/payment_awaiting_handler.dart';
import '../utils/payment_status_poller.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/payment_dialogs.dart';
import 'widgets/payment_method_tile.dart';
import 'widgets/verify_app_bar.dart';
import 'widgets/verify_format.dart';

/// Phương thức thanh toán hiển thị trên màn thanh toán.
/// - Chuyển khoản: active (VietQR từ BE `bankInfo`)
/// - Thẻ tín dụng/ghi nợ: khóa — sắp ra mắt
const _kAvailableMethods = <PaymentMethod>[
  PaymentMethod.bankTransfer,
];

const _kDisplayedMethods = <PaymentMethod>[
  PaymentMethod.bankTransfer,
  PaymentMethod.card,
];

/// Screen 5 — Thanh toán (manual bank-transfer reconcile, TTL 24h).
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with WidgetsBindingObserver {
  PaymentMethod _selected = PaymentMethod.bankTransfer;
  bool _processing = false;
  bool _awaitingReconcile = false;
  bool _syncingQuote = false;
  PaymentStatusPoller? _poller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumePendingSession();
      _syncQuoteFromServer();
    });
  }

  Future<void> _syncQuoteFromServer() async {
    final verifyState = ref.read(verifyFlowControllerProvider);
    if (verifyState.selectedPlan == null) return;

    final session = verifyState.paymentSession;
    final hasPendingSession = session != null &&
        verifyState.paymentStatus == PaymentStatus.pending &&
        DateTime.now().isBefore(session.expiresAt);
    if (hasPendingSession) return;

    final quote = verifyState.paymentQuote;
    if (quote != null && !quote.isCatalogFallback) return;

    setState(() => _syncingQuote = true);
    try {
      await ref.read(verifyFlowControllerProvider.notifier).ensureFreshQuote();
    } on VerifyApiException catch (e) {
      if (mounted) showPaymentApiError(context, e);
    } finally {
      if (mounted) setState(() => _syncingQuote = false);
    }
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

  void _resumePendingSession() {
    final verifyState = ref.read(verifyFlowControllerProvider);
    final session = verifyState.paymentSession;
    if (session == null) return;
    if (verifyState.paymentStatus == PaymentStatus.paid) return;
    if (DateTime.now().isAfter(session.expiresAt)) return;
    if (verifyState.paymentStatus != PaymentStatus.pending) return;

    setState(() {
      _processing = true;
      _awaitingReconcile = true;
    });
    _startPolling(session.expiresAt);
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

      if (_selected == PaymentMethod.bankTransfer) {
        _showBankTransferDialog(session);
      }
      setState(() => _awaitingReconcile = true);
      _startPolling(session.expiresAt);
    } on VerifyApiException catch (e) {
      if (!mounted) return;
      showPaymentApiError(context, e);
      AnalyticsService.logEvent('verify_payment_session_failed', params: {
        'method': _selected.name,
      });
      setState(() {
        _processing = false;
        _awaitingReconcile = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      _showError('Khởi tạo thanh toán thất bại: $msg');
      AnalyticsService.logEvent('verify_payment_session_failed', params: {
        'method': _selected.name,
      });
      setState(() {
        _processing = false;
        _awaitingReconcile = false;
      });
    }
  }

  void _showBankTransferDialog(PaymentSession session) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BankTransferDialog(
        session: session,
        onWaitAndClose: () {
          if (!mounted) return;
          _showInfo(
            'Đã ghi nhận. Bạn sẽ nhận thông báo khi thanh toán được xác nhận.',
          );
        },
        onCancelSession: _cancelPaymentSession,
      ),
    );
  }

  Future<void> _cancelPaymentSession() async {
    try {
      await ref.read(verifyFlowControllerProvider.notifier).cancelPayment();
      if (!mounted) return;
      _stopPolling(clearFcm: true);
      setState(() {
        _processing = false;
        _awaitingReconcile = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showError(
        'Huỷ phiên thất bại: ${e.toString().replaceAll('Exception: ', '')}',
      );
      rethrow;
    }
  }

  void _startPolling(DateTime expiresAt) {
    _stopPolling(clearFcm: false);
    _wireFcmListener();

    _poller = PaymentStatusPoller(
      expiresAt: expiresAt,
      onPoll: _pollOnce,
      onExpired: () {
        if (!mounted) return;
        setState(() {
          _processing = false;
          _awaitingReconcile = false;
        });
        _stopPolling(clearFcm: true);
        _showInfo(
          'Phiên thanh toán đã hết hạn. Vui lòng tạo phiên mới nếu chưa '
          'chuyển khoản.',
        );
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
      await handlePaymentStatusUpdate(
        status: status,
        context: context,
        ref: ref,
        onPollingStopped: () => _stopPolling(clearFcm: true),
        setProcessing: (v) => setState(() {
          _processing = v;
          _awaitingReconcile = v;
        }),
      );
    } catch (_) {
      // silent retry — poller schedule tiếp
    }
  }

  void _wireFcmListener() {
    PushNotificationService.instance.onForegroundData = (data) {
      if (!isPaymentPaidPush(data)) return;
      _poller?.checkNow();
    };
  }

  void _stopPolling({required bool clearFcm}) {
    _poller?.stop();
    _poller = null;
    if (clearFcm) {
      PushNotificationService.instance.onForegroundData = null;
    }
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

  bool _hasPendingPayment() {
    final verifyState = ref.read(verifyFlowControllerProvider);
    final session = verifyState.paymentSession;
    if (session == null) return false;
    if (verifyState.paymentStatus == PaymentStatus.paid) return false;
    if (DateTime.now().isAfter(session.expiresAt)) return false;
    return verifyState.paymentStatus == PaymentStatus.pending ||
        _awaitingReconcile;
  }

  Future<void> _handleBack() async {
    if (!_hasPendingPayment()) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
      return;
    }

    final confirmed = await confirmClosePendingPayment(
      context,
      isBankTransfer: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _cancelPaymentSession();
    } catch (_) {
      return;
    }
    if (!mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final plan = state.selectedPlan;

    if (plan == null) {
      return Scaffold(
        appBar: const VerifyAppBar(
          overline: 'BƯỚC 2/2 · MUA GÓI',
          title: 'Thanh toán',
          currentStep: 2,
          totalSteps: 2,
        ),
        body:
            const Center(child: Text('Chưa chọn plan — quay lại bước trước.')),
      );
    }

    final quote = state.paymentQuote;
    if (quote == null) {
      return Scaffold(
        appBar: const VerifyAppBar(
          overline: 'BƯỚC 2/2 · MUA GÓI',
          title: 'Thanh toán',
          currentStep: 2,
          totalSteps: 2,
        ),
        body: const Center(
          child: Text('Chưa có báo giá — quay lại chọn gói.'),
        ),
      );
    }

    final total = quote.totalAmount;
    final quoteReady = !quote.isCatalogFallback && !_syncingQuote;

    return PopScope(
      canPop: !_hasPendingPayment(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: VerifyAppBar(
          overline: 'BƯỚC 2/2 · MUA GÓI',
          title: 'Thanh toán',
          currentStep: 2,
          totalSteps: 2,
          onBack: _handleBack,
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
                if (_syncingQuote) ...[
                  const StatusStrip(
                    icon: Icons.sync,
                    label: 'Đang đồng bộ giá từ máy chủ',
                    subtitle: 'Vui lòng đợi vài giây trước khi thanh toán.',
                    variant: StatusStripVariant.brand,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else if (quote.isCatalogFallback) ...[
                  StatusStrip(
                    icon: Icons.warning_amber_outlined,
                    label: 'Chưa đồng bộ được giá chính thức',
                    subtitle: 'Chạm "Tải lại giá" bên dưới hoặc kiểm tra mạng.',
                    variant: StatusStripVariant.warning,
                    trailing: TextButton(
                      onPressed: _syncingQuote ? null : _syncQuoteFromServer,
                      child: const Text('Tải lại giá'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_awaitingReconcile) ...[
                  StatusStrip(
                    icon: Icons.schedule,
                    label: 'Đang chờ đối soát thủ công',
                    subtitle:
                        'Có thể mất 1–3 giờ. Bạn có thể đóng app — sẽ nhận '
                        'thông báo khi xác nhận thành công.',
                    variant: StatusStripVariant.brand,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                OrderSummaryCard.fromQuote(plan: plan, quote: quote)
                    .animate()
                    .fadeIn(duration: 320.ms),
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
                ..._kDisplayedMethods.asMap().entries.map((e) {
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
                      'Nếu không hài lòng, yêu cầu hoàn tiền trong vòng 14 '
                      'ngày kể từ thanh toán.',
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
                    onPressed:
                        _processing || !quoteReady ? null : _handlePay,
                    icon: _processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.darkBg,
                            ),
                          )
                        : const Icon(Icons.lock_outline, size: 18),
                    label: Text(
                      _processing
                          ? 'Đang chờ đối soát...'
                          : _syncingQuote
                              ? 'Đang tải giá...'
                              : !quoteReady
                                  ? 'Chờ đồng bộ giá'
                                  : 'Thanh toán an toàn '
                                      '${VerifyFormat.priceVND(total)}',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
