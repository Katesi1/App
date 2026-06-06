import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../data/repositories/verify_repository.dart';
import '../views/widgets/verify_format.dart';

/// Hiển thị snackbar cho lỗi payment/quote từ BE (tiếng Việt).
void showPaymentApiError(BuildContext context, VerifyApiException e) {
  final colors = context.colors;
  String message = e.vietnameseMessage;

  if (e.isDowngradeScheduled && e.effectiveAt != null) {
    message = 'Gói mới áp dụng từ ${VerifyFormat.dateVN(e.effectiveAt!)}';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: e.isDowngradeScheduled ? colors.brand : colors.error,
      duration: const Duration(seconds: 5),
    ),
  );
}

void showRenewBlockedMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: context.colors.error,
      duration: const Duration(seconds: 4),
    ),
  );
}
