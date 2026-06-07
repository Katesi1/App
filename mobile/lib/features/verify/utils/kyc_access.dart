import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/utils/dashboard_refresh.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Message tiếng Việt theo trạng thái KYC trên profile.
String kycGateMessage(UserModel? user) {
  return switch (user?.kycStatus) {
    'pending' =>
      'Hồ sơ đang chờ admin duyệt. Vui lòng chờ kết quả trước khi thanh toán.',
    'rejected' =>
      'Hồ sơ xác minh chưa được duyệt. Vui lòng bổ sung và gửi lại.',
    'approved' => 'KYC đã được duyệt. Bạn có thể chọn gói và thanh toán.',
    _ => 'Cần xác minh tài khoản trước khi thanh toán.',
  };
}

/// Route KYC phù hợp — source of truth `user.kycStatus`.
String kycGateRoute(UserModel? user) {
  return switch (user?.kycStatus) {
    'pending' => '/verify/pending',
    'rejected' => '/verify/rejected',
    'approved' => UserModel.subscriptionEntryRoute,
    _ => '/verify/cccd-front',
  };
}

bool userNeedsKycVerification(UserModel? user) =>
    user != null && user.isOwner && !user.isKycApproved;

/// Toast + điều hướng tới bước KYC đúng trạng thái.
void showKycRequiredAndNavigate(BuildContext context, WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  AppSnackBar.info(context, kycGateMessage(user));
  context.go(kycGateRoute(user));
}

/// Chặn tạo phiên thanh toán/QR khi chưa KYC approved.
/// Trả `true` nếu được phép tiếp tục; `false` nếu đã redirect sang KYC.
bool ensureKycApprovedForPayment(BuildContext context, WidgetRef ref) {
  if (!userNeedsKycVerification(ref.read(currentUserProvider))) {
    return true;
  }
  showKycRequiredAndNavigate(context, ref);
  return false;
}

/// Pop stack nếu có; không thì về dashboard (màn quản lý chủ/sale/admin).
void popVerifyFlowOrDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go('/dashboard');
}

/// Sau KYC submit — refresh profile + stats rồi về dashboard để banner pending
/// hiện ngay (không cần user pull-to-refresh).
Future<void> returnToDashboardAfterKyc(
  BuildContext context,
  WidgetRef ref,
) async {
  await refreshDashboardData(ref);
  if (!context.mounted) return;
  context.go('/dashboard');
}

/// Đồng bộ `user.kycStatus = pending` sau submit nếu profile chưa kịp cập nhật.
void syncUserKycPendingAfterSubmit(WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  if (user == null || !user.isOwner || user.kycStatus == 'pending') {
    return;
  }
  ref.read(authProvider.notifier).replaceUser(
        user.copyWith(kycStatus: 'pending'),
      );
}
