import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/utils/viet_qr_url.dart';
import '../../data/models/payment_session.dart';
import '../../utils/payment_close_confirm.dart';
import '../../utils/payment_countdown_format.dart';
import 'verify_format.dart';

/// Trang thanh toán chuyển khoản — VietQR + STK + nội dung CK (từ BE `bankInfo`).
///
/// Trước đây là dialog; nay là trang full-screen (push qua root navigator) để
/// có không gian rõ ràng hơn. Logic giữ nguyên: countdown, copy, đóng-và-đợi,
/// đóng phiên. Caller (payment/subscription screen) vẫn poll trạng thái và pop
/// trang này khi `paid` qua `handlePaymentStatusUpdate(popDialog: true)`.
class BankTransferScreen extends StatefulWidget {
  final PaymentSession session;
  final VoidCallback? onWaitAndClose;
  final Future<void> Function()? onCancelSession;

  const BankTransferScreen({
    super.key,
    required this.session,
    this.onWaitAndClose,
    this.onCancelSession,
  });

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recalc();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_recalc);
    });
  }

  void _recalc() {
    final deadline = widget.session.qrExpiresAt ?? widget.session.expiresAt;
    _remaining = deadline.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    AppToast.success(context, 'Đã sao chép $label');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bank = widget.session.bankInfo;
    final expired = _remaining.inSeconds <= 0;

    if (bank == null || !bank.isComplete) {
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(title: const Text('Chuyển khoản ngân hàng')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: colors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Thiếu thông tin tài khoản từ hệ thống',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng thử lại hoặc liên hệ hỗ trợ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final transferContent = bank.content;
    final qrUrl = VietQrUrl.build(
      bankCode: bank.bankName,
      accountNumber: bank.accountNumber,
      accountName: bank.accountName,
      amount: widget.session.totalAmount,
      content: transferContent,
    );

    return PaymentDialogPopScope(
      isBankTransfer: true,
      onCancelSession: widget.onCancelSession,
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          backgroundColor: colors.bgSurface,
          title: const Text('Chuyển khoản ngân hàng'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.brand.withValues(alpha: 0.14),
                            colors.brandSecondary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.borderBrand.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Số tiền cần chuyển',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            VerifyFormat.priceVND(widget.session.totalAmount),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colors.textBrand,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderDefault),
                        boxShadow: [
                          BoxShadow(
                            color: colors.brand.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: qrUrl,
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                          memCacheWidth: 440,
                          placeholder: (_, __) => const SizedBox(
                            width: 220,
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => SizedBox(
                            width: 220,
                            height: 220,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 48,
                                  color: colors.textTertiary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Không tải được QR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.borderDefault),
                      ),
                      child: Column(
                        children: [
                          _row(
                            context,
                            label: 'Ngân hàng',
                            value: bank.bankName,
                            copyable: false,
                            leading: bank.bankLogoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedNetworkImage(
                                      imageUrl: bank.bankLogoUrl!,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                      memCacheWidth: 56,
                                      errorWidget: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  )
                                : null,
                          ),
                          Divider(height: 1, color: colors.borderSubtle),
                          _row(
                            context,
                            label: 'Số tài khoản',
                            value: bank.accountNumber,
                            enabled: !expired,
                          ),
                          Divider(height: 1, color: colors.borderSubtle),
                          _row(
                            context,
                            label: 'Tên người nhận',
                            value: bank.accountName,
                            copyable: false,
                          ),
                          Divider(height: 1, color: colors.borderSubtle),
                          _row(
                            context,
                            label: 'Nội dung CK',
                            value: transferContent,
                            enabled: !expired,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: expired
                            ? colors.errorBg
                            : colors.bgSurfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            expired
                                ? Icons.timer_off_outlined
                                : Icons.timer_outlined,
                            size: 14,
                            color:
                                expired ? colors.error : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expired
                                ? 'Phiên đã hết hạn — tạo phiên mới'
                                : widget.session.qrExpiresAt != null
                                    ? 'QR hết hạn sau '
                                        '${formatPaymentCountdown(_remaining)}'
                                    : 'Hết hạn sau '
                                        '${formatPaymentCountdown(_remaining)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  expired ? colors.error : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.info.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: colors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đối soát thủ công 1–3 giờ. Có thể đóng app — '
                              'bạn sẽ nhận thông báo khi thanh toán được xác nhận.',
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
                    const SizedBox(height: 14),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton.icon(
                        onPressed: expired
                            ? null
                            : () {
                                widget.onWaitAndClose?.call();
                                PaymentDialogPopScope.maybeOf(context)
                                    ?.popKeepingSession();
                              },
                        icon: const Icon(Icons.notifications_active_outlined,
                            size: 18),
                        label: const Text('Đóng và đợi'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => _cancelSessionAndClose(context),
                        child: const Text('Đóng phiên'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelSessionAndClose(BuildContext context) async {
    final confirmed = await confirmClosePendingPayment(
      context,
      isBankTransfer: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await widget.onCancelSession?.call();
    } catch (_) {
      // Đóng dialog dù API lỗi — màn payment xử lý snackbar nếu cần.
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String value,
    bool copyable = true,
    bool enabled = true,
    Color? valueColor,
    FontWeight? valueWeight,
    Widget? leading,
  }) {
    final colors = context.colors;
    final canCopy = copyable && enabled;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textTertiary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: valueWeight ?? FontWeight.w700,
                    color: valueColor ?? colors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.content_copy_rounded,
                size: 16,
                color: colors.brand,
              ),
            ),
        ],
      ),
    );

    if (!canCopy) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _copy(label, value),
        child: content,
      ),
    );
  }
}
