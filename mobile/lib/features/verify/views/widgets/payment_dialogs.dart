import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/viet_qr_url.dart';
import '../../data/models/payment_session.dart';
import '../../utils/payment_close_confirm.dart';
import '../../utils/payment_countdown_format.dart';
import 'payment_qr_view.dart';
import 'verify_format.dart';

/// VNPay QR dialog — render QR thật từ session, đếm ngược + nút mở app banking.
class VNPayQRDialog extends StatefulWidget {
  final PaymentSession session;

  const VNPayQRDialog({super.key, required this.session});

  @override
  State<VNPayQRDialog> createState() => _VNPayQRDialogState();
}

class _VNPayQRDialogState extends State<VNPayQRDialog> {
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
    _remaining = widget.session.expiresAt.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _openBankApp() async {
    final url = widget.session.payUrl ?? widget.session.redirectUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expired = _remaining.inSeconds <= 0;
    final hasQr =
        (widget.session.qrCode != null && widget.session.qrCode!.isNotEmpty) ||
            (widget.session.qrImageBase64 != null &&
                widget.session.qrImageBase64!.isNotEmpty);
    final canOpenBankApp =
        (widget.session.payUrl != null && widget.session.payUrl!.isNotEmpty) ||
            (widget.session.redirectUrl != null &&
                widget.session.redirectUrl!.isNotEmpty);

    // Backend prod hiện chưa có VNPay createQR API → trả `qrCode = null` cho
    // VNPay QR (xem `api-payments-frontend-spec.md` §7.1). FE rơi xuống
    // branch redirect: hiển thị CTA mở payUrl thay vì placeholder QR rỗng.
    final useRedirectMode = !hasQr && canOpenBankApp;

    return PaymentDialogPopScope(
      child: Dialog(
        backgroundColor: colors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    useRedirectMode ? Icons.open_in_browser : Icons.qr_code_2,
                    size: 18,
                    color: colors.textBrand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    useRedirectMode
                        ? 'Thanh toán qua VNPay'
                        : 'Quét QR bằng app ngân hàng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (useRedirectMode)
                _RedirectIllustration(disabled: expired)
              else
                PaymentQrView(
                  payload: widget.session.qrCode,
                  imageBase64: widget.session.qrImageBase64,
                  size: 220,
                ),
              const SizedBox(height: 14),
              Text(
                VerifyFormat.priceVND(widget.session.totalAmount),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textBrand,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      expired ? AppColors.coral50 : colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      expired ? Icons.error_outline : Icons.timer_outlined,
                      size: 12,
                      color:
                          expired ? AppColors.coral700 : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      expired
                          ? 'Phiên đã hết hạn — tạo lại từ đầu'
                          : 'Hết hạn sau ${_fmt(_remaining)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            expired ? AppColors.coral700 : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: colors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        useRedirectMode
                            ? 'Bạn sẽ được chuyển sang cổng VNPay để chọn ngân hàng và xác nhận thanh toán.'
                            : 'Sau khi thanh toán xong, app sẽ tự xác nhận trong vài giây.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (canOpenBankApp)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: expired ? null : _openBankApp,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      useRedirectMode ? 'Mở cổng VNPay' : 'Mở app ngân hàng',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (canOpenBankApp) const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => _confirmClose(context),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await confirmClosePendingPayment(context);
    if (confirmed && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Bank transfer dialog — VietQR + STK + nội dung CK (từ BE `bankInfo`).
class BankTransferDialog extends StatefulWidget {
  final PaymentSession session;
  final VoidCallback? onWaitAndClose;
  final Future<void> Function()? onCancelSession;

  const BankTransferDialog({
    super.key,
    required this.session,
    this.onWaitAndClose,
    this.onCancelSession,
  });

  @override
  State<BankTransferDialog> createState() => _BankTransferDialogState();
}

class _BankTransferDialogState extends State<BankTransferDialog> {
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
    _remaining = widget.session.expiresAt.difference(DateTime.now());
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bank = widget.session.bankInfo;
    final expired = _remaining.inSeconds <= 0;

    if (bank == null || !bank.isComplete) {
      return Dialog(
        backgroundColor: colors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 32),
              const SizedBox(height: 12),
              Text(
                'Thiếu thông tin tài khoản từ hệ thống',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng thử lại hoặc liên hệ hỗ trợ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Đóng'),
                ),
              ),
            ],
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
      child: Dialog(
        backgroundColor: colors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 22,
                      color: colors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuyển khoản ngân hàng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Quét mã hoặc chuyển thủ công',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                      expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                      size: 14,
                      color: expired ? colors.error : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      expired
                          ? 'Phiên đã hết hạn — tạo phiên mới'
                          : 'Hết hạn sau ${formatPaymentCountdown(_remaining)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: expired ? colors.error : colors.textSecondary,
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
                          Navigator.of(context).maybePop();
                          widget.onWaitAndClose?.call();
                        },
                  icon:
                      const Icon(Icons.notifications_active_outlined, size: 18),
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

/// Placeholder visual cho VNPay redirect mode (khi backend trả `qrCode=null`,
/// chỉ có `payUrl`). Thay vì vùng QR rỗng gây hiểu nhầm, hiển thị icon
/// browser + caption hướng dẫn để CTA "Mở cổng VNPay" thành flow chính.
class _RedirectIllustration extends StatelessWidget {
  final bool disabled;
  const _RedirectIllustration({required this.disabled});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 220,
      height: 168,
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: disabled
                  ? colors.bgSurfaceElevated
                  : colors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 28,
              color: disabled ? colors.textTertiary : colors.brand,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bấm nút bên dưới để mở cổng thanh toán VNPay',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
