import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_history_item.dart';
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
      if (context.mounted) showPaymentApiError(context, e, ref: ref);
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
    if (context.mounted) showPaymentApiError(context, e, ref: ref);
    return null;
  }

  if (onRetryAfterCancel == null) return null;

  try {
    return await onRetryAfterCancel();
  } on VerifyApiException catch (e) {
    if (context.mounted) showPaymentApiError(context, e, ref: ref);
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
  return showModalBottomSheet<_PaymentPendingChoice>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PaymentPendingSheet(error: error),
  );
}

class _PaymentPendingSheet extends StatelessWidget {
  final VerifyApiException error;

  const _PaymentPendingSheet({required this.error});

  String? _kindLabel(PaymentHistoryKind? kind) {
    if (kind == null) return null;
    switch (kind) {
      case PaymentHistoryKind.subscription:
        return 'Mua gói lần đầu';
      case PaymentHistoryKind.renew:
        return 'Gia hạn';
      case PaymentHistoryKind.upgrade:
        return 'Nâng cấp';
      case PaymentHistoryKind.downgrade:
        return 'Hạ gói';
      case PaymentHistoryKind.refund:
        return 'Hoàn tiền';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pending = error.pendingSession;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phiên thanh toán đang chờ',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.vietnameseMessage,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pending != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderDefault),
              ),
              child: Column(
                children: [
                  if (_kindLabel(pending.kind) != null)
                    _SummaryRow(
                      icon: Icons.label_outline,
                      label: 'Loại',
                      value: _kindLabel(pending.kind)!,
                    ),
                  if (pending.planLabel != null &&
                      pending.planLabel!.isNotEmpty) ...[
                    if (_kindLabel(pending.kind) != null)
                      const SizedBox(height: 10),
                    _SummaryRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Gói',
                      value: pending.planLabel!,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.payments_outlined,
                    label: 'Số tiền',
                    value: VerifyFormat.priceVND(pending.totalAmount),
                    highlight: true,
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.timer_outlined,
                    label: 'Hết hạn',
                    value: '${VerifyFormat.dateVN(pending.expiresAt)} '
                        '${VerifyFormat.time(pending.expiresAt)}',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_PaymentPendingChoice.resume),
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: Text(
                'Tiếp tục phiên cũ',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pop(_PaymentPendingChoice.cancelAndRetry),
              icon: Icon(Icons.cancel_outlined, size: 18, color: colors.error),
              label: Text(
                'Huỷ phiên & tạo mới',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w600,
                  color: colors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textTertiary,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.beVietnamPro(
                  fontSize: highlight ? 16 : 14,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                  color: highlight ? colors.textBrand : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
