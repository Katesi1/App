import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/repositories/verify_repository.dart';
import '../views/widgets/verify_format.dart';
import 'kyc_access.dart';

/// Toast / dialog cho lỗi payment/quote từ BE (tiếng Việt).
void showPaymentApiError(
  BuildContext context,
  VerifyApiException e, {
  WidgetRef? ref,
}) {
  if (e.isKycNotApproved && ref != null) {
    showKycRequiredAndNavigate(context, ref);
    return;
  }

  if (e.isDowngradeScheduled) {
    showDowngradeScheduledDialog(context, e);
    return;
  }

  AppToast.error(context, e.vietnameseMessage);
}

/// 409 `downgradeScheduled` — coi như thành công, không hiện lỗi generic.
Future<void> showDowngradeScheduledDialog(
  BuildContext context,
  VerifyApiException e,
) async {
  final colors = context.colors;
  final planLabel = UserModel.planLabelFor(e.pendingPlanId);
  final effective = e.effectiveAt != null
      ? VerifyFormat.dateVN(e.effectiveAt!)
      : 'kỳ tiếp theo';

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Đã đặt lịch hạ gói',
        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Gói $planLabel sẽ áp dụng từ $effective.\n\n'
        'Bạn vẫn dùng gói hiện tại cho đến ngày đó.',
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          height: 1.45,
          color: colors.textSecondary,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Đã hiểu',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

void showRenewBlockedMessage(BuildContext context, String message) {
  AppToast.error(context, message);
}
