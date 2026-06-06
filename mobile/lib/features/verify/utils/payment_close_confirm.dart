import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';

/// Xác nhận trước khi huỷ phiên thanh toán chưa hoàn tất.
///
/// Trả về `true` nếu user chọn **Đóng phiên** (huỷ bill trên BE).
/// `false` = tiếp tục thanh toán.
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
        isBankTransfer ? 'Huỷ phiên thanh toán?' : 'Huỷ phiên thanh toán?',
        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
      ),
      content: Text(
        isBankTransfer
            ? 'Giao dịch chưa được xác nhận.\n\n'
                '• Đóng phiên — huỷ bill này trên hệ thống. '
                'Admin sẽ không phải duyệt phiên đã huỷ.\n\n'
                '• Nếu bạn đã chuyển khoản, hãy quay lại và chọn '
                '"Đóng và đợi" để hệ thống tiếp tục đối soát (1–3 giờ).'
            : 'Thanh toán chưa được xác nhận. Đóng màn hình này sẽ huỷ '
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
            'Đóng phiên',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result == true;
}

/// Bọc dialog thanh toán — chặn back/barrier dismiss trừ khi user xác nhận.
class PaymentDialogPopScope extends StatefulWidget {
  final Widget child;
  final bool isBankTransfer;
  final Future<void> Function()? onCancelSession;

  const PaymentDialogPopScope({
    super.key,
    required this.child,
    this.isBankTransfer = false,
    this.onCancelSession,
  });

  static PaymentDialogPopScopeState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<PaymentDialogPopScopeState>();
  }

  @override
  State<PaymentDialogPopScope> createState() => PaymentDialogPopScopeState();
}

class PaymentDialogPopScopeState extends State<PaymentDialogPopScope> {
  bool _allowPop = false;

  /// Đóng dialog nhưng **giữ** phiên `pending` — dùng cho "Đóng và đợi".
  void popKeepingSession() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _handleCancelSession(BuildContext context) async {
    final confirmed = await confirmClosePendingPayment(
      context,
      isBankTransfer: widget.isBankTransfer,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await widget.onCancelSession?.call();
    } catch (_) {
      // Vẫn đóng dialog — caller có thể hiện snackbar nếu cần.
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleCancelSession(context);
      },
      child: widget.child,
    );
  }
}
