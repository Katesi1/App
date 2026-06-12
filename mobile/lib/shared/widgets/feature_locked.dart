import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_failure.dart';
import '../../data/models/user_model.dart';
import 'app_toast.dart';

/// Xử lý lỗi 403 business từ BE (Apple IAP compliance v1.12) ở các call site
/// write: tạo/sửa property, mời nhân viên.
///
/// - `subscription.featureLocked` (hết trial / chưa mua gói) → hiện message của
///   BE + CTA "Mua gói" dẫn tới luồng chọn gói (Android giữ thanh toán).
/// - `kyc.propertyRequiresKyc` → CTA dẫn tới luồng KYC.
///
/// Trả `true` nếu đã xử lý (caller nên `return` sớm, không hiện snackbar generic).
/// Trả `false` nếu không phải lỗi business → caller fallback snackbar thường.
bool handleFeatureLocked(
  BuildContext context,
  ApiFailure failure,
  UserModel user,
) {
  if (failure.isKycRequired) {
    AppToast.show(
      context,
      message: failure.message,
      type: AppToastType.warning,
      actionLabel: 'Xác minh ngay →',
      onAction: () => context.push('/verify/cccd-front'),
    );
    return true;
  }

  if (failure.isFeatureLocked) {
    AppToast.show(
      context,
      message: failure.message,
      type: AppToastType.warning,
      actionLabel: 'Mua gói →',
      onAction: () => context.push(user.subscriptionPlanPickerRoute),
    );
    return true;
  }

  return false;
}
