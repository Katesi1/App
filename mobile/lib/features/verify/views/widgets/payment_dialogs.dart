import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/payment_session.dart';
import 'payment_qr_view.dart';
import 'verify_format.dart';

/// VNPay QR dialog — renders the real QR from the session, countdown + button to open the bank app.
class VNPayQRDialog extends StatefulWidget {
  final PaymentSession session;

  const VNPayQRDialog({super.key, required this.session});

  @override
  State<VNPayQRDialog> createState() => _VNPayQRDialogState();
}

class _VNPayQRDialogState extends State<VNPayQRDialog>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recalc();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
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
    // When the user opens a banking app (VNPay flow), this screen goes to the
    // background. Cancel the 1s ticker to save CPU/battery and resume on return.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _ticker?.cancel();
      _ticker = null;
    } else if (state == AppLifecycleState.resumed && _ticker == null) {
      // Sync the countdown immediately so the user doesn't see stale time.
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

    // Backend prod doesn't have the VNPay createQR API yet → returns
    // `qrCode = null` for VNPay QR (see `api-payments-frontend-spec.md` §7.1).
    // FE falls back to the redirect branch: show the "Open payUrl" CTA
    // instead of an empty QR placeholder.
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

/// Bank transfer dialog — VietQR + account number + transfer memo + per-field copy.
class BankTransferDialog extends StatefulWidget {
  final PaymentSession session;

  const BankTransferDialog({super.key, required this.session});

  @override
  State<BankTransferDialog> createState() => _BankTransferDialogState();
}

class _BankTransferDialogState extends State<BankTransferDialog>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recalc();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
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
            if (bank.vietQrPayload != null && bank.vietQrPayload!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PaymentQrView(payload: bank.vietQrPayload, size: 200),
              ),
            _row(context,
                label: 'Ngân hàng', value: bank.bankName, copyable: false),
            _row(context, label: 'Số tài khoản', value: bank.accountNumber),
            _row(context,
                label: 'Tên người nhận',
                value: bank.accountName,
                copyable: false),
            _row(context, label: 'Nội dung CK', value: bank.content),
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
                          'Vui lòng giữ nguyên nội dung CK để hệ thống nhận diện đúng giao dịch.',
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

/// Visual placeholder for VNPay redirect mode (when backend returns
/// `qrCode=null` and only `payUrl`). Instead of an empty/confusing QR area,
/// show a browser icon + caption so the "Open VNPay gateway" CTA becomes the
/// primary flow.
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
