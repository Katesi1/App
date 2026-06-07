import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'kyc_access.dart';

export 'kyc_access.dart'
    show
        kycGateMessage,
        kycGateRoute,
        userNeedsKycVerification,
        showKycRequiredAndNavigate,
        ensureKycApprovedForPayment,
        popVerifyFlowOrDashboard;

/// Rời màn chi tiết gói — pop stack nếu có, không thì về dashboard.
void popSubscriptionDetailOrDashboard(BuildContext context) {
  popVerifyFlowOrDashboard(context);
}

/// Sau 「Đóng và đợi」 hoặc 「Đóng phiên」 trên dialog thanh toán.
void goToSubscriptionDetail(BuildContext context) {
  context.go('/verify/subscription-detail');
}
