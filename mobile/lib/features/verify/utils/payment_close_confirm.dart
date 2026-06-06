import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';

/// Xác nhận trước khi đóng phiên thanh toán chưa hoàn tất.
///
/// Trả về `true` nếu user chọn đóng/huỷ phiên.
Future<bool> confirmClosePendingPayment(
  BuildContext context, {
  bool isBankTransfer = false,
}) async {
  final colors = context.colors;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        isBankTransfer ? 'Rời khỏi màn thanh toán?' : 'Huỷ phiên thanh toán?',
        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
      ),
      content: Text(
        isBankTransfer
            ? 'Giao dịch chưa được xác nhận.\n\n'
                '• Nếu bạn chưa chuyển khoản, phiên sẽ bị huỷ và cần '
                'tạo lại khi thanh toán sau.\n\n'
                '• Nếu đã chuyển khoản, hãy chọn "Đóng và đợi" để hệ '
                'thống tiếp tục đối soát (có thể mất 1–3 giờ).'
            : 'Thanh toán chưa được xác nhận. Đóng màn hình này có thể huỷ '
                'phiên hiện tại và bạn sẽ cần thanh toán lại.',
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          height: 1.45,
          color: colors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Tiếp tục thanh toán',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            isBankTransfer ? 'Đóng phiên' : 'Huỷ phiên',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result == true;
}

/// Bọc dialog thanh toán — chặn back/barrier dismiss trừ khi user xác nhận.
class PaymentDialogPopScope extends StatelessWidget {
  final Widget child;
  final bool isBankTransfer;
  final VoidCallback? onConfirmedClose;

  const PaymentDialogPopScope({
    super.key,
    required this.child,
    this.isBankTransfer = false,
    this.onConfirmedClose,
  });

  Future<void> _handleCloseAttempt(BuildContext context) async {
    final confirmed = await confirmClosePendingPayment(
      context,
      isBankTransfer: isBankTransfer,
    );
    if (!confirmed || !context.mounted) return;
    onConfirmedClose?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleCloseAttempt(context);
      },
      child: child,
    );
  }
}
