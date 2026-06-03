import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/payment_session.dart';
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
    final hasQr = (widget.session.qrCode != null &&
            widget.session.qrCode!.isNotEmpty) ||
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

    return Dialog(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: expired ? AppColors.coral50 : colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    expired ? Icons.error_outline : Icons.timer_outlined,
                    size: 12,
                    color: expired ? AppColors.coral700 : colors.textSecondary,
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
                    useRedirectMode
                        ? 'Mở cổng VNPay'
                        : 'Mở app ngân hàng',
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
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Bank transfer dialog — VietQR + STK + nội dung CK + nút copy từng field.
class BankTransferDialog extends StatefulWidget {
  final PaymentSession session;

  const BankTransferDialog({super.key, required this.session});

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

    // Nội dung CK: ưu tiên từ bankInfo, fallback dùng sessionId để đối soát.
    final transferContent = bank?.content.isNotEmpty == true
        ? bank!.content
        : widget.session.sessionId;

    // VietQR động — encode sẵn số tiền + nội dung, khách quét là tự điền.
    final qrUrl = AppConstants.vietQrUrl(
      amount: widget.session.totalAmount,
      content: transferContent,
    );

    return Dialog(
      backgroundColor: colors.bgSurfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance,
                    size: 18, color: colors.brandSecondary),
                const SizedBox(width: 6),
                Text(
                  'Chuyển khoản ngân hàng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // VietQR động — số tiền + nội dung đã được encode vào QR.
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderDefault),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: qrUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Image.asset(
                    AppConstants.bankingQrAsset,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quét QR — số tiền tự điền sẵn',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // Thông tin tài khoản — từ backend hoặc fallback constants.
            _row(context,
                label: 'Ngân hàng',
                value: bank?.bankName ?? AppConstants.bankDisplayName,
                copyable: false),
            _row(context,
                label: 'Số tài khoản',
                value: bank?.accountNumber ?? AppConstants.bankAccountNumber),
            _row(context,
                label: 'Tên người nhận',
                value: bank?.accountName ?? AppConstants.bankAccountName,
                copyable: false),
            // Nội dung CK + số tiền — luôn hiển thị.
            _row(context, label: 'Nội dung CK', value: transferContent),
            _row(
              context,
              label: 'Số tiền',
              value: VerifyFormat.priceVND(widget.session.totalAmount),
              copyable: false,
              valueColor: colors.textBrand,
              valueWeight: FontWeight.w800,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đối soát có thể mất 5–30 phút.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vui lòng nhập đúng nội dung CK để hệ thống nhận diện đúng giao dịch.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colors.textTertiary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              expired
                  ? 'Phiên đã hết hạn — vui lòng tạo phiên mới'
                  : 'Phiên hết hạn sau ${_fmt(_remaining)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: expired ? AppColors.coral700 : colors.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
                fontSize: 13,
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

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
