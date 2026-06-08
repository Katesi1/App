import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/monitoring/analytics_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/status_strip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import '../utils/billing_preflight.dart';
import '../utils/payment_close_confirm.dart';
import '../utils/payment_error_handler.dart';
import '../utils/payment_awaiting_handler.dart';
import '../utils/payment_pending_handler.dart';
import '../utils/payment_status_poller.dart';
import '../utils/verify_flow_navigation.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapPaymentScreen();
      if (mounted) await _syncQuoteFromServer();
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
      if (mounted) showPaymentApiError(context, e, ref: ref);
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

  Future<void> _bootstrapPaymentScreen() async {
    PaymentSession? session;
    try {
      session = await fetchActivePendingSession(ref);
    } on VerifyApiException catch (e) {
      if (mounted) showPaymentApiError(context, e, ref: ref);
      return;
    }
    if (session == null) return;

    await hydratePendingSession(ref, session);
    if (!mounted) return;

    setState(() => _awaitingReconcile = true);
    _startPolling(session.expiresAt);
  }

  Future<void> _reopenPaymentDialog() async {
    var session = ref.read(verifyFlowControllerProvider).paymentSession;
    try {
      session ??= await fetchActivePendingSession(ref);
    } catch (_) {
      return;
    }
    if (!mounted || session == null) return;

    await hydratePendingSession(ref, session);
    if (!mounted) return;

    setState(() => _awaitingReconcile = true);
    _showBankTransferDialog(session);
    _startPolling(session.expiresAt);
  }

  Future<void> _handlePay() async {
    if (!ensureKycApprovedForPayment(context, ref)) {
      return;
    }

    if (_hasPendingPayment()) {
      await _reopenPaymentDialog();
      return;
    }

    final canProceed = await guardActivePendingPayment(
      context: context,
      ref: ref,
      onResume: (session) {
        if (!mounted) return;
        setState(() => _awaitingReconcile = true);
        _showBankTransferDialog(session);
        _startPolling(session.expiresAt);
      },
    );
    if (!canProceed || !mounted) return;

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
      if (e.isPaymentPending) {
        final session = await resolvePaymentPendingConflict(
          context: context,
          ref: ref,
          error: e,
          onRetryAfterCancel: () => ref
              .read(verifyFlowControllerProvider.notifier)
              .initiatePayment(_selected),
        );
        if (!mounted) return;
        if (session != null) {
          if (_selected == PaymentMethod.bankTransfer) {
            _showBankTransferDialog(session);
          }
          setState(() => _awaitingReconcile = true);
          _startPolling(session.expiresAt);
          return;
        }
        setState(() {
          _processing = false;
          _awaitingReconcile = false;
        });
        return;
      }
      showPaymentApiError(context, e, ref: ref);
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            goToSubscriptionDetail(context);
          });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        goToSubscriptionDetail(context);
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
        successRoute: _onboardingSuccessRoute(ref),
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
    AppToast.info(context, msg);
  }

  void _showError(String msg) {
    AppToast.error(context, msg);
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
    if (_awaitingReconcile) {
      goToSubscriptionDetail(context);
      return;
    }

    if (!_hasPendingPayment()) {
      if (context.canPop()) {
        context.pop();
      } else {
        popVerifyFlowOrDashboard(context);
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
    final hasPending = _hasPendingPayment();
    final session = state.paymentSession;

    return PopScope(
      canPop: !_hasPendingPayment(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: VerifyAppBar(
          overline: hasPending ? 'ĐƠN ĐANG CHỜ' : 'BƯỚC 2/2 · MUA GÓI',
          title: hasPending ? 'Tiếp tục thanh toán' : 'Thanh toán',
          currentStep: hasPending ? null : 2,
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
                if (hasPending) ...[
                  _PendingOrderBanner(
                    session: session,
                    plan: plan,
                    totalAmount: total,
                    onViewQR: _reopenPaymentDialog,
                  ).animate().fadeIn(duration: 280.ms),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  if (_syncingQuote) ...[
                    const StatusStrip(
                      icon: Icons.sync,
                      label: 'Đang đồng bộ giá từ máy chủ',
                      subtitle:
                          'Vui lòng đợi vài giây trước khi thanh toán.',
                      variant: StatusStripVariant.brand,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else if (quote.isCatalogFallback) ...[
                    StatusStrip(
                      icon: Icons.warning_amber_outlined,
                      label: 'Chưa đồng bộ được giá chính thức',
                      subtitle:
                          'Chạm "Tải lại giá" bên dưới hoặc kiểm tra mạng.',
                      variant: StatusStripVariant.warning,
                      trailing: TextButton(
                        onPressed: _syncingQuote ? null : _syncQuoteFromServer,
                        child: const Text('Tải lại giá'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
                OrderSummaryCard.fromQuote(
                  plan: plan,
                  quote: quote,
                  user: ref.watch(currentUserProvider),
                  hasPendingPaymentSession: hasPending,
                ).animate().fadeIn(duration: 320.ms),
                if (!hasPending) ...[
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
                    subtitle: 'Nếu không hài lòng, yêu cầu hoàn tiền trong '
                        'vòng 14 ngày kể từ thanh toán.',
                    variant: StatusStripVariant.brand,
                  ),
                ],
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomBar(
                hasPending: hasPending,
                processing: _processing,
                quoteReady: quoteReady,
                syncingQuote: _syncingQuote,
                total: total,
                onPay: _handlePay,
                onViewQR: _reopenPaymentDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Order Banner ────────────────────────────────────────────────────

class _PendingOrderBanner extends StatelessWidget {
  final PaymentSession? session;
  final Plan plan;
  final int totalAmount;
  final VoidCallback onViewQR;

  const _PendingOrderBanner({
    required this.session,
    required this.plan,
    required this.totalAmount,
    required this.onViewQR,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warnColor = colors.warning;
    final warnBg = colors.warningBg;

    return Container(
      decoration: BoxDecoration(
        color: warnBg,
        border: Border.all(
          color: warnColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: warnColor.withValues(alpha: isDark ? 0.14 : 0.09),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(
                  color: warnColor.withValues(alpha: isDark ? 0.2 : 0.15),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: warnColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: warnColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CÓ ĐƠN ĐANG CHỜ THANH TOÁN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: warnColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Bạn đã tạo đơn này trước đó. '
                        'Hoàn tất chuyển khoản để kích hoạt gói.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Info cells ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: _InfoCell(
                    icon: Icons.attach_money_rounded,
                    label: 'Số tiền',
                    value: VerifyFormat.priceVND(totalAmount),
                    valueColor: warnColor,
                    bold: true,
                  ),
                ),
                const SizedBox(width: 10),
                if (session != null)
                  Expanded(
                    child: _InfoCell(
                      icon: Icons.schedule_rounded,
                      label: 'Hết hạn lúc',
                      value:
                          '${VerifyFormat.time(session!.expiresAt)} · '
                          '${VerifyFormat.dateVN(session!.expiresAt)}',
                    ),
                  ),
              ],
            ),
          ),
          if (session?.bankInfo?.content != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _InfoCell(
                icon: Icons.edit_note_rounded,
                label: 'Nội dung chuyển khoản',
                value: session!.bankInfo!.content,
                valueColor: colors.textBrand,
                bold: true,
              ),
            ),
          ],
          // ── View QR button ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: FilledButton.icon(
              onPressed: onViewQR,
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text('Xem mã QR & Chuyển khoản'),
              style: FilledButton.styleFrom(
                backgroundColor: warnColor,
                foregroundColor: isDark ? colors.bgCanvas : Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: colors.textTertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? colors.textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool hasPending;
  final bool processing;
  final bool quoteReady;
  final bool syncingQuote;
  final int total;
  final VoidCallback onPay;
  final VoidCallback onViewQR;

  const _BottomBar({
    required this.hasPending,
    required this.processing,
    required this.quoteReady,
    required this.syncingQuote,
    required this.total,
    required this.onPay,
    required this.onViewQR,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomInset + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: hasPending
          ? _buildPendingButton(context, colors, isDark)
          : _buildPayButton(context, colors),
    );
  }

  Widget _buildPendingButton(
    BuildContext context,
    AppColorScheme colors,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onViewQR,
            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
            label: const Text('Xem mã QR & Chuyển khoản'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.warning,
              foregroundColor: isDark ? colors.bgCanvas : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Đơn này do bạn tạo trước đó — không phải đơn mới',
          style: TextStyle(
            fontSize: 11,
            color: colors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPayButton(BuildContext context, AppColorScheme colors) {
    final disabled = processing || !quoteReady;
    String label;
    if (processing) {
      label = 'Đang chờ đối soát...';
    } else if (syncingQuote) {
      label = 'Đang tải giá...';
    } else if (!quoteReady) {
      label = 'Chờ đồng bộ giá';
    } else {
      label = 'Thanh toán an toàn ${VerifyFormat.priceVND(total)}';
    }

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: disabled ? null : onPay,
        icon: processing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.darkBg,
                ),
              )
            : const Icon(Icons.lock_outline, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// Subscription đầu tiên sau KYC approved → trial screen; còn lại → chi tiết gói.
String _onboardingSuccessRoute(WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  final isFirstSubscription =
      user?.isKycApproved == true && user?.subscriptionStatus == 'none';
  return isFirstSubscription
      ? '/verify/approved'
      : '/verify/subscription-detail';
}
