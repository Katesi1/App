import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/models/verify_enums.dart';

/// Xử lý kết quả poll payment — dùng chung payment + renewal screens.
Future<bool> handlePaymentStatusUpdate({
  required PaymentStatus status,
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onPollingStopped,
  required void Function(bool processing) setProcessing,
  String successRoute = '/verify/subscription-detail',
  bool popDialog = true,
}) async {
  if (status == PaymentStatus.paid) {
    onPollingStopped();
    if (!context.mounted) return true;
    if (popDialog && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await ref.read(authProvider.notifier).refreshProfile();
    if (!context.mounted) return true;
    setProcessing(false);
    context.pushReplacement(successRoute);
    return true;
  }

  if (status == PaymentStatus.failed || status == PaymentStatus.expired) {
    onPollingStopped();
    if (context.mounted) {
      setProcessing(false);
      AppToast.error(
        context,
        'Thanh toán thất bại hoặc phiên đã hết hạn',
      );
    }
    return true;
  }

  return false;
}

/// FCM `data` payload có phải thông báo payment paid không.
bool isPaymentPaidPush(Map<String, dynamic> data) {
  final type = (data['type'] ?? '').toString().toLowerCase();
  final targetType = (data['targetType'] ?? data['target_type'] ?? '')
      .toString()
      .toLowerCase();
  final status = (data['status'] ?? '').toString().toLowerCase();
  if (status == 'paid') return true;
  if (type == 'payment' && status.isEmpty) return true;
  if (targetType == 'payment' && status.isEmpty) return true;
  return false;
}
