import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

/// Xác nhận trước khi huỷ phiên thanh toán chưa hoàn tất.
///
/// Trả về `true` nếu user chọn **Đóng phiên** (huỷ bill trên BE).
/// `false` = tiếp tục thanh toán.
Future<bool> confirmClosePendingPayment(
  BuildContext context, {
  bool isBankTransfer = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ClosePaymentDialog(isBankTransfer: isBankTransfer),
  );
  return result == true;
}

class _ClosePaymentDialog extends StatelessWidget {
  final bool isBankTransfer;

  const _ClosePaymentDialog({required this.isBankTransfer});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.bgSurfaceElevated,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon cảnh báo ──────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.report_gmailerrorred_rounded,
                size: 34,
                color: colors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Huỷ phiên thanh toán?',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Giao dịch hiện tại chưa được xác nhận.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Nội dung chi tiết ──────────────────────────────────────
            if (isBankTransfer) ...[
              _ReasonRow(
                icon: Icons.cancel_outlined,
                iconColor: colors.error,
                tint: colors.error,
                title: 'Đóng phiên sẽ huỷ bill này',
                desc: 'Hệ thống huỷ đơn — admin sẽ không phải duyệt '
                    'phiên đã huỷ.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReasonRow(
                icon: Icons.schedule_rounded,
                iconColor: colors.info,
                tint: colors.info,
                title: 'Đã chuyển khoản rồi?',
                desc: 'Quay lại và chọn “Đóng và đợi” để hệ thống tiếp tục '
                    'đối soát (1–3 giờ).',
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.errorBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Đóng màn hình này sẽ huỷ phiên hiện tại và bạn sẽ cần '
                  'thanh toán lại từ đầu.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // ── Hành động ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: colors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Tiếp tục thanh toán',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Đóng phiên',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.error,
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

/// Một dòng lý do — icon tròn tint + tiêu đề + mô tả.
class _ReasonRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String desc;

  const _ReasonRow({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
