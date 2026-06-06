import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import 'payment_error_handler.dart';
import '../views/widgets/verify_format.dart';

enum _PaymentPendingChoice { resume, cancelAndRetry }

/// Xử lý 409 `paymentPending` — cho user tiếp tục phiên cũ hoặc huỷ & tạo mới.
///
/// Trả về [PaymentSession] nếu resume thành công hoặc retry sau huỷ thành công.
Future<PaymentSession?> resolvePaymentPendingConflict({
  required BuildContext context,
  required WidgetRef ref,
  required VerifyApiException error,
  Future<PaymentSession> Function()? onRetryAfterCancel,
}) async {
  if (!error.isPaymentPending) return null;

  final choice = await _showPaymentPendingDialog(context, error);
  if (!context.mounted || choice == null) return null;

  final notifier = ref.read(verifyFlowControllerProvider.notifier);

  if (choice == _PaymentPendingChoice.resume) {
    try {
      final session = await notifier.syncActivePaymentFromApi();
      if (!context.mounted) return null;
      if (session == null) {
        showRenewBlockedMessage(
          context,
          'Không tải được phiên thanh toán đang chờ. '
          'Thử huỷ phiên cũ và tạo mới.',
        );
        return null;
      }
      return session;
    } on VerifyApiException catch (e) {
      if (context.mounted) showPaymentApiError(context, e);
      return null;
    }
  }

  final sessionId = error.pendingSession?.sessionId;
  if (sessionId == null || sessionId.isEmpty) {
    if (context.mounted) {
      showRenewBlockedMessage(
        context,
        'Không xác định được phiên cũ. Vui lòng thử lại sau.',
      );
    }
    return null;
  }

  try {
    await notifier.cancelPaymentById(sessionId);
  } on VerifyApiException catch (e) {
    if (context.mounted) showPaymentApiError(context, e);
    return null;
  }

  if (onRetryAfterCancel == null) return null;

  try {
    return await onRetryAfterCancel();
  } on VerifyApiException catch (e) {
    if (context.mounted) showPaymentApiError(context, e);
    return null;
  } catch (_) {
    if (context.mounted) {
      showRenewBlockedMessage(
        context,
        'Tạo phiên mới thất bại. Vui lòng thử lại.',
      );
    }
    return null;
  }
}

Future<_PaymentPendingChoice?> _showPaymentPendingDialog(
  BuildContext context,
  VerifyApiException error,
) {
  final colors = context.colors;
  final pending = error.pendingSession;
  final detailLines = <String>[];
  if (pending?.planLabel != null && pending!.planLabel!.isNotEmpty) {
    detailLines.add('Gói: ${pending.planLabel}');
  }
  if (pending != null) {
    detailLines.add('Số tiền: ${VerifyFormat.priceVND(pending.totalAmount)}');
    detailLines.add(
      'Hết hạn: ${VerifyFormat.dateVN(pending.expiresAt)} '
      '${VerifyFormat.time(pending.expiresAt)}',
    );
  }

  return showDialog<_PaymentPendingChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Phiên thanh toán đang chờ',
        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.vietnameseMessage,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          if (detailLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...detailLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_PaymentPendingChoice.resume),
          child: Text(
            'Tiếp tục phiên cũ',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(ctx).pop(_PaymentPendingChoice.cancelAndRetry),
          child: Text(
            'Huỷ & tạo mới',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
