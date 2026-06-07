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
import '../data/models/payment_session.dart';
import '../data/models/verify_enums.dart';
import '../data/repositories/verify_repository_impl.dart';
import 'widgets/payment_dialogs.dart';
import 'widgets/quote_summary_card.dart';
import 'widgets/verify_app_bar.dart';
import 'widgets/verify_format.dart';

/// Screen 5 — Payment.
///
/// Single payment method: VietQR bank transfer (Apple IAP + VNPay removed —
/// backend only accepts `bank_transfer`, reconciled manually by admin). Flow:
/// create session → show VietQR dialog → poll status (with back-off) until
/// admin marks it paid, or the user closes and waits for the FCM push.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _processing = false;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;

  /// True while a [BankTransferDialog] is on screen — so [_onPaid] only pops a
  /// dialog (never the payment screen itself).
  bool _dialogOpen = false;

  /// Bumped on every new session. The dialog's dismissal handler is gated on
  /// this so a stale dialog (e.g. the expired one after "Tạo mã mới") can't
  /// cancel the polling / reset state of the fresh session that replaced it.
  int _payGen = 0;

  // Quote (POST /payments/quote) — BE là source of truth cho số tiền + kind.
  PaymentQuote? _quote;
  bool _loadingQuote = true;
  String? _quoteError;
  bool _frozen = false; // subscriptionFrozen → chặn thanh toán

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _loadingQuote = true;
      _quoteError = null;
      _frozen = false;
    });
    try {
      final quote =
          await ref.read(verifyFlowControllerProvider.notifier).getQuote();
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _loadingQuote = false;
      });
    } on VerifyApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingQuote = false;
        if (e.isSubscriptionFrozen) {
          _frozen = true;
        } else {
          _quoteError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingQuote = false;
        _quoteError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handlePay() async {
    // Số tiền PHẢI từ quote (API). Không có quote thì không cho thanh toán —
    // tuyệt đối không tự tính local (tiền thật).
    final quote = _quote;
    if (quote == null) {
      _showError('Chưa lấy được báo giá. Vui lòng thử lại.');
      _loadQuote();
      return;
    }
    final gen = ++_payGen;
    _pollTimer?.cancel(); // supersede any in-flight session before starting.
    AnalyticsService.logEvent('verify_payment_submit', params: const {
      'method': 'bank_transfer',
    });
    setState(() => _processing = true);
    try {
      final session =
          await ref.read(verifyFlowControllerProvider.notifier).initiatePayment(
                PaymentMethod.bankTransfer,
                totalAmount: quote.totalAmount,
              );
      AnalyticsService.logEvent('verify_payment_session_created', params: {
        'method': 'bank_transfer',
        'amount': session.totalAmount,
      });

      if (!mounted) return;

      // Session created → the modal dialog now gates interaction, so re-enable
      // the underlying CTA (it's covered by the barrier anyway). This avoids a
      // stuck "Đang xử lý..." state if the user later dismisses the dialog.
      setState(() => _processing = false);
      _showSessionDialog(session, gen);
    } on VerifyApiException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      if (e.isDowngradeScheduled) {
        _onDowngradeScheduled(e);
      } else if (e.isSubscriptionFrozen) {
        setState(() => _frozen = true);
      } else if (e.isPaymentPending) {
        _onPaymentPending(e);
      } else {
        _showError('Khởi tạo thanh toán thất bại: ${e.message}');
      }
      AnalyticsService.logEvent('verify_payment_session_failed',
          params: {'method': 'bank_transfer', 'code': e.code ?? ''});
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      _showError('Khởi tạo thanh toán thất bại: $msg');
      AnalyticsService.logEvent('verify_payment_session_failed', params: const {
        'method': 'bank_transfer',
      });
      setState(() => _processing = false);
    }
  }

  /// BE trả 409 `downgradeScheduled` — đã đặt lịch hạ gói (không charge, không
  /// session). Refresh profile để lấy `pendingPlanId`/`pendingEffectiveAt` rồi
  /// rời màn.
  Future<void> _onDowngradeScheduled(VerifyApiException e) async {
    await ref.read(verifyFlowControllerProvider.notifier).refreshUserProfile();
    if (!mounted) return;
    final when = e.effectiveAt;
    _showInfo(when != null
        ? 'Đã đặt lịch hạ gói. Áp dụng từ ${VerifyFormat.dateVN(when)}.'
        : 'Đã đặt lịch hạ gói. Áp dụng từ kỳ tiếp theo.');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  /// Mở QR dialog cho 1 session + bắt đầu polling. Dùng cho cả phiên mới tạo và
  /// phiên resume (409 paymentPending). `gen` chốt session hiện tại để handler
  /// đóng dialog không can thiệp lên phiên mới hơn.
  void _showSessionDialog(PaymentSession session, int gen) {
    _dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BankTransferDialog(
        session: session,
        onCloseAndWait: _handleCloseAndWait,
        onCreateNew: _handlePay,
        onCancel: () async {
          await ref
              .read(verifyFlowControllerProvider.notifier)
              .cancelPayment(session.sessionId);
          _pollTimer?.cancel();
          _dialogOpen = false;
          if (!mounted) return;
          setState(() => _processing = false);
          _showInfo('Đã huỷ phiên chuyển khoản.');
        },
      ),
    ).then((_) {
      if (gen != _payGen) return;
      _dialogOpen = false;
      _pollTimer?.cancel();
    });
    _startPolling();
  }

  /// BE trả 409 `paymentPending` — user đã có phiên chờ. Hỏi: tiếp tục đợi
  /// (resume QR cũ qua `GET /payments/active`) hay huỷ phiên cũ rồi tạo lại.
  Future<void> _onPaymentPending(VerifyApiException e) async {
    final pending = e.pendingSession;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đang có phiên chờ thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.message),
            if (pending != null) ...[
              const SizedBox(height: 10),
              Text(
                '${pending.planLabel ?? ''} · '
                '${VerifyFormat.priceVND(pending.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (pending.expiresAt != null)
                Text(
                  'Hết hạn: ${VerifyFormat.dateVN(pending.expiresAt!)}',
                  style: TextStyle(
                      fontSize: 12, color: context.colors.textTertiary),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Huỷ phiên cũ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('wait'),
            child: const Text('Tiếp tục đợi'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == 'wait') {
      // Resume — lấy phiên đầy đủ (qrCode/bankInfo) rồi mở lại QR.
      final gen = ++_payGen;
      _pollTimer?.cancel();
      try {
        final active = await ref
            .read(verifyFlowControllerProvider.notifier)
            .getActivePayment();
        if (!mounted) return;
        if (active != null) {
          _showSessionDialog(active, gen);
        } else {
          // Phiên đã biến mất → thử tạo lại.
          _handlePay();
        }
      } catch (err) {
        if (!mounted) return;
        _showError(err.toString().replaceAll('Exception: ', ''));
      }
    } else if (choice == 'cancel' && pending != null) {
      // Huỷ phiên cũ rồi tạo lại.
      try {
        await ref
            .read(verifyFlowControllerProvider.notifier)
            .cancelPayment(pending.sessionId);
        if (!mounted) return;
        _handlePay();
      } catch (err) {
        if (!mounted) return;
        _showError('Huỷ phiên cũ thất bại: '
            '${err.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  /// User confirms they've transferred → stop active polling and leave. The
  /// subscription activates asynchronously via the `subscription_paid` FCM push
  /// + app-resume profile refresh; the dashboard banner reflects it.
  void _handleCloseAndWait() {
    _pollTimer?.cancel();
    _dialogOpen = false;
    if (!mounted) return;
    setState(() => _processing = false);
    _showInfo(
      'Đã ghi nhận. Chúng tôi sẽ thông báo và kích hoạt gói ngay khi nhận '
      'được chuyển khoản.',
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  /// Poll interval grows with elapsed time so we don't hammer the backend for
  /// the whole 24h window: 3s for the first 30s (covers fast/sandbox reconcile),
  /// then 10s up to 2 min, 30s up to 10 min, 60s after that. Manual admin
  /// reconcile typically lands within 1–3 hours anyway.
  Duration _nextPollDelay() {
    final elapsed = DateTime.now().difference(_pollStartedAt ?? DateTime.now());
    if (elapsed < const Duration(seconds: 30)) {
      return const Duration(seconds: 3);
    }
    if (elapsed < const Duration(minutes: 2)) {
      return const Duration(seconds: 10);
    }
    if (elapsed < const Duration(minutes: 10)) {
      return const Duration(seconds: 30);
    }
    return const Duration(seconds: 60);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollStartedAt = DateTime.now();
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer = Timer(_nextPollDelay(), _poll);
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final status = await ref
          .read(verifyFlowControllerProvider.notifier)
          .checkPaymentStatus();
      if (!mounted) return;
      if (status == PaymentStatus.paid) {
        await _onPaid();
        return;
      } else if (status == PaymentStatus.failed ||
          status == PaymentStatus.expired) {
        setState(() => _processing = false);
        _showError('Phiên thanh toán đã kết thúc. Vui lòng tạo mã mới.');
        return;
      }
    } catch (_) {
      // Silent retry — keep polling on transient network errors.
    }
    if (mounted) _scheduleNextPoll();
  }

  Future<void> _onPaid() async {
    _pollTimer?.cancel();
    // Supersede the current session so the dialog's dismissal handler (fired by
    // the pop below) doesn't fight our navigation.
    _payGen++;
    // Pull the freshly-activated subscription into currentUserProvider so the
    // dashboard banner + route guards update immediately.
    await ref.read(verifyFlowControllerProvider.notifier).refreshUserProfile();
    if (!mounted) return;
    // Close the QR dialog only if one is actually open — never the screen.
    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpen = false;
    }
    // KYC decoupled from purchase: if admin already approved → subscription
    // detail; else → pending (waiting on KYC approval).
    final verifyStatus = ref.read(verifyFlowControllerProvider).status;
    final target = verifyStatus == VerifyStatus.approved
        ? '/verify/subscription-detail'
        : '/verify/pending';
    context.pushReplacement(target);
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
          overline: 'NÂNG GÓI · SUBSCRIPTION',
          title: 'Thanh toán',
        ),
        body:
            const Center(child: Text('Chưa chọn plan — quay lại bước trước.')),
      );
    }

    final planName = plan.tier.displayName;
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: const VerifyAppBar(
        overline: 'NÂNG GÓI · SUBSCRIPTION',
        title: 'Thanh toán',
      ),
      body: _buildBody(colors, planName),
    );
  }

  Widget _buildBody(AppColorScheme colors, String planName) {
    if (_loadingQuote) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_frozen) {
      return _FrozenView(onContact: () => context.push('/profile/help'));
    }
    if (_quoteError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 12),
              Text(
                _quoteError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadQuote, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final quote = _quote!;
    final isDowngrade = quote.kind == TransactionKind.downgrade;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
          children: isDowngrade
              ? [_DowngradeNotice(planName: planName)]
              : [
                  QuoteSummaryCard(quote: quote, planName: planName)
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
                  _VietQrMethodCard()
                      .animate()
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: 0.05, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  const StatusStrip(
                    icon: Icons.schedule_outlined,
                    label: 'Đối soát thủ công — thường 1–3 giờ',
                    subtitle:
                        'Sau khi chuyển khoản, gói sẽ tự kích hoạt khi hệ thống xác nhận. Bạn có thể đóng app và đợi thông báo.',
                    variant: StatusStripVariant.brand,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const StatusStrip(
                    icon: Icons.lock_outline,
                    label: 'Hoàn tiền 100% trong 14 ngày',
                    subtitle:
                        'Nếu không hài lòng, yêu cầu hoàn tiền trong vòng 14 ngày kể từ thanh toán.',
                    variant: StatusStripVariant.neutral,
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
                    : Icon(isDowngrade
                        ? Icons.trending_down_rounded
                        : Icons.qr_code_2),
                label: Text(
                  _processing
                      ? 'Đang xử lý...'
                      : isDowngrade
                          ? 'Xác nhận hạ gói'
                          : 'Tạo mã VietQR · ${VerifyFormat.priceVND(quote.totalAmount)}',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hiển thị khi subscription đang frozen — chặn thanh toán, mời liên hệ HT.
class _FrozenView extends StatelessWidget {
  final VoidCallback onContact;
  const _FrozenView({required this.onContact});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ac_unit_rounded, size: 44, color: colors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Gói đăng ký đang tạm khoá',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Tài khoản đang bị đóng băng nên không thể thanh toán/gia hạn. '
              'Vui lòng liên hệ hỗ trợ để được mở lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: const Text('Liên hệ hỗ trợ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thông báo hạ gói — không charge ngay, áp dụng từ kỳ sau (BE deferred).
class _DowngradeNotice extends StatelessWidget {
  final String planName;
  const _DowngradeNotice({required this.planName});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down_rounded, color: colors.warning),
              const SizedBox(width: 8),
              Text(
                'Hạ xuống gói $planName',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Hạ gói KHÔNG tính phí ngay. Gói mới sẽ áp dụng từ kỳ tiếp theo '
            '(khi kỳ hiện tại kết thúc). Bạn vẫn dùng quyền lợi gói hiện tại '
            'tới hết kỳ.',
            style: TextStyle(
                color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Single, always-selected VietQR bank-transfer method tile.
class _VietQrMethodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderBrand),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_balance,
                size: 22, color: colors.brandSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuyển khoản VietQR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quét QR hoặc copy STK + nội dung CK trong app ngân hàng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 20, color: colors.brandSecondary),
        ],
      ),
    );
  }
}
