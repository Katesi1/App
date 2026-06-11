import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../data/models/payment_session.dart';
import '../../data/models/verify_enums.dart';
import 'payment_qr_view.dart';
import 'verify_format.dart';

/// VietQR bank-transfer dialog — the only payment method (Apple IAP + VNPay
/// removed). Renders the QR, copyable account number + transfer memo, a 24h
/// countdown driven by [PaymentSession.expiresAt], and a manual-reconcile
/// notice. When the session expires the user can mint a new code without
/// leaving the dialog.
///
/// Callbacks:
///  - [onCloseAndWait]: user transferred and wants to leave — stop active
///    polling; the subscription activates via FCM `subscription_paid` push +
///    app-resume profile refresh.
///  - [onCreateNew]: session expired — re-initiate a fresh payment session.
///  - [onCancel]: user abandons the transfer — after a confirmation, this is
///    awaited to void (cancel) the pending bill on the backend. When `null`,
///    the "Đóng" button just dismisses the dialog without a server call.
class BankTransferDialog extends StatefulWidget {
  final PaymentSession session;
  final VoidCallback? onCloseAndWait;
  final VoidCallback? onCreateNew;
  final Future<void> Function()? onCancel;

  const BankTransferDialog({
    super.key,
    required this.session,
    this.onCloseAndWait,
    this.onCreateNew,
    this.onCancel,
  });

  @override
  State<BankTransferDialog> createState() => _BankTransferDialogState();
}

class _BankTransferDialogState extends State<BankTransferDialog>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  /// True while the cancel API call is in flight (disables the close button).
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recalc();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    // 1s ticks are fine even for a 24h window — the dialog is short-lived and
    // the ticker is paused while the app is backgrounded (see lifecycle hook).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_recalc);
    });
  }

  void _recalc() {
    _remaining = widget.session.expiresAt.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _ticker?.cancel();
      _ticker = null;
    } else if (state == AppLifecycleState.resumed && _ticker == null) {
      if (mounted) setState(_recalc);
      _startTicker();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    AppToast.success(context, 'Đã sao chép $label');
  }

  /// Close handler for the bottom "Đóng" button. When an [onCancel] handler is
  /// wired AND the session is still live, confirm with the user then void the
  /// pending bill on the backend before dismissing. Otherwise just dismiss.
  Future<void> _handleClose() async {
    final expired = _remaining.inSeconds <= 0;
    if (widget.onCancel == null || expired) {
      Navigator.of(context).maybePop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ phiên chuyển khoản?'),
        content: const Text(
          'Mã VietQR hiện tại sẽ bị huỷ và không còn hiệu lực. Nếu bạn đã '
          'chuyển khoản, hãy chọn "Tôi đã chuyển — đóng & đợi" thay vì huỷ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Huỷ phiên'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await widget.onCancel!.call();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      AppToast.error(
        context,
        'Huỷ phiên thất bại: '
        '${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bank = widget.session.bankInfo;
    final expired = _remaining.inSeconds <= 0;

    if (bank == null) {
      return AlertDialog(
        title: const Text('Chuyển khoản ngân hàng'),
        content: const Text('Không nhận được thông tin tài khoản từ máy chủ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Đóng'),
          ),
        ],
      );
    }

    // QR source priority: raw EMVCo payload (compact, scales) → img.vietqr.io
    // quick-link built from bankInfo (amount + memo baked in). Both come from
    // the backend `bankInfo`; nothing is hardcoded.
    final qrImageUrl = bank.vietQrPayload == null || bank.vietQrPayload!.isEmpty
        ? bank.vietQrImageUrl(widget.session.totalAmount)
        : null;

    return PopScope(
      // Back button / system gesture must NOT silently close a live session —
      // route it through the same confirm-then-cancel flow as the "Đóng" button.
      canPop: widget.onCancel == null || expired,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleClose();
      },
      child: Dialog(
        backgroundColor: colors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: title + compact countdown pill.
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.brandSecondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.qr_code_2_rounded,
                        size: 18, color: colors.brandSecondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuyển khoản VietQR',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (widget.session.kind != null)
                          Text(
                            widget.session.kind!.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: expired
                          ? AppColors.coral50
                          : colors.bgSurfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          expired
                              ? Icons.error_outline_rounded
                              : Icons.schedule_rounded,
                          size: 12,
                          color: expired
                              ? AppColors.coral700
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expired ? 'Hết hạn' : _fmtRemaining(_remaining),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: expired
                                ? AppColors.coral700
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!expired &&
                  ((bank.vietQrPayload != null &&
                          bank.vietQrPayload!.isNotEmpty) ||
                      qrImageUrl != null))
                PaymentQrView(
                  payload: bank.vietQrPayload,
                  imageUrl: qrImageUrl,
                  size: 188,
                ),
              const SizedBox(height: 14),
              // Amount — the single most important number, highlighted card.
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.brand.withValues(alpha: 0.12),
                      colors.brandSecondary.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: colors.brand.withValues(alpha: 0.18)),
                ),
                child: Column(
                  children: [
                    Text(
                      'SỐ TIỀN CẦN CHUYỂN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      VerifyFormat.priceVND(widget.session.totalAmount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colors.textBrand,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Account info card — copy icon sits inline on copyable rows.
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderDefault),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _row(context,
                        label: 'Ngân hàng',
                        value: bank.bankName,
                        copyable: false),
                    _divider(colors),
                    _row(context,
                        label: 'Số tài khoản', value: bank.accountNumber),
                    _divider(colors),
                    _row(context,
                        label: 'Tên người nhận',
                        value: bank.accountName,
                        copyable: false),
                    _divider(colors),
                    _row(context, label: 'Nội dung CK', value: bank.content),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Reconcile note.
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 15, color: colors.textBrand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đối soát thủ công, thường 1–3 giờ trong giờ hành chính. '
                        'Giữ nguyên nội dung CK — bạn có thể đóng app, chúng tôi '
                        'sẽ báo khi nhận được tiền.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (expired)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                      widget.onCreateNew?.call();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tạo mã mới'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                      widget.onCloseAndWait?.call();
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 18),
                    label: const Text('Tôi đã chuyển — đóng & đợi'),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: _cancelling ? null : _handleClose,
                  child: _cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.onCancel != null && !expired
                              ? 'Huỷ phiên chuyển khoản'
                              : 'Đóng',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(AppColorScheme colors) => Divider(
        height: 1,
        thickness: 1,
        color: colors.borderDefault.withValues(alpha: 0.6),
      );

  Widget _row(
    BuildContext context, {
    required String label,
    required String value,
    bool copyable = true,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: valueWeight ?? FontWeight.w700,
                color: valueColor ?? colors.textPrimary,
              ),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () => _copy(label, value),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.content_copy,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Human-readable remaining time for the 24h session window. Shows days +
  /// hours when far out, hours + minutes within a day, and MM:SS in the final
  /// hour — never a raw "1440:00" MM:SS string.
  String _fmtRemaining(Duration d) {
    if (d.inDays >= 1) {
      final h = d.inHours % 24;
      return '${d.inDays} ngày $h giờ';
    }
    if (d.inHours >= 1) {
      final m = d.inMinutes % 60;
      return '${d.inHours} giờ $m phút';
    }
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Dialog hiển thị khi BE trả 409 `paymentPending` — user đã có một phiên chờ
/// thanh toán. Thay cho `AlertDialog` thô (vốn show thẳng message tiếng Anh từ
/// BE). Trả về qua [Navigator.pop]:
///  - `'wait'`   → tiếp tục đợi (resume QR cũ)
///  - `'cancel'` → huỷ phiên cũ rồi tạo phiên mới
///  - `null`     → đóng, không làm gì
class PendingPaymentDialog extends StatelessWidget {
  final PendingSessionInfo? pending;

  const PendingPaymentDialog({super.key, this.pending});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = pending;
    final expiry = p?.expiresAt;
    return Dialog(
      backgroundColor: colors.bgSurfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header — icon đồng hồ chờ + tiêu đề.
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      size: 21, color: AppColors.warningText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đang có phiên chờ thanh toán',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Bạn đã có một mã thanh toán đang chờ chuyển khoản. Vui lòng hoàn '
              'tất phiên này, hoặc huỷ để tạo mã mới.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            if (p != null) ...[
              const SizedBox(height: 16),
              // Chi tiết phiên cũ — card nổi bật giống order summary.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Column(
                  children: [
                    _detailRow(
                      colors,
                      label: 'Gói đăng ký',
                      value: p.planLabel?.isNotEmpty == true
                          ? p.planLabel!
                          : (p.kind?.label ?? 'Thanh toán'),
                    ),
                    const SizedBox(height: 10),
                    _detailRow(
                      colors,
                      label: 'Số tiền',
                      value: VerifyFormat.priceVND(p.totalAmount),
                      emphasize: true,
                    ),
                    if (expiry != null) ...[
                      const SizedBox(height: 10),
                      _detailRow(
                        colors,
                        label: 'Hết hạn',
                        value: VerifyFormat.dateVN(expiry),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop('wait'),
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text('Tiếp tục thanh toán'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed:
                    p == null ? null : () => Navigator.of(context).pop('cancel'),
                style: TextButton.styleFrom(foregroundColor: colors.error),
                child: const Text('Huỷ phiên cũ & tạo mã mới'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    AppColorScheme colors, {
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: emphasize ? 16 : 13.5,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              color: emphasize ? colors.textBrand : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
