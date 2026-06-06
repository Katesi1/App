import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Rời màn chi tiết gói — pop stack nếu có, không thì về dashboard.
void popSubscriptionDetailOrDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go('/dashboard');
}

/// Sau 「Đóng và đợi」 hoặc 「Đóng phiên」 trên dialog thanh toán.
void goToSubscriptionDetail(BuildContext context) {
  context.go('/verify/subscription-detail');
}
