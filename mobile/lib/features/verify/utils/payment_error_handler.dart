import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_toast.dart';
import '../data/repositories/verify_repository.dart';
import '../views/widgets/verify_format.dart';
import 'kyc_access.dart';

/// Toast phía trên cho lỗi payment/quote từ BE (tiếng Việt).
void showPaymentApiError(
  BuildContext context,
  VerifyApiException e, {
  WidgetRef? ref,
}) {
  if (e.isKycNotApproved && ref != null) {
    showKycRequiredAndNavigate(context, ref);
    return;
  }

  String message = e.vietnameseMessage;

  if (e.isDowngradeScheduled && e.effectiveAt != null) {
    message = 'Gói mới áp dụng từ ${VerifyFormat.dateVN(e.effectiveAt!)}';
  }

  if (e.isDowngradeScheduled) {
    AppToast.info(context, message);
  } else {
    AppToast.error(context, message);
  }
}

void showRenewBlockedMessage(BuildContext context, String message) {
  AppToast.error(context, message);
}
