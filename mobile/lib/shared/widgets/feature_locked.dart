import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_failure.dart';
import '../../data/models/user_model.dart';
import 'app_toast.dart';

/// Route màn cập nhật hồ sơ cá nhân (chứa field SĐT).
const String _profileEditRoute = '/profile/edit';

/// Xử lý lỗi 403 business từ BE ở các call site write: tạo/sửa property,
/// mời nhân viên.
///
/// - `kyc.propertyRequiresKyc` → CTA dẫn tới luồng KYC.
/// - `PHONE_REQUIRED` (v1.41) → CTA dẫn tới màn cập nhật hồ sơ để nhập SĐT.
/// - `PROPERTY_LIMIT_REACHED` (v1.39) → message trung tính + CTA liên hệ hỗ trợ.
/// - `subscription.featureLocked` (hết trial / chưa mua gói) → hiện message của
///   BE + CTA "Mua gói" dẫn tới luồng chọn gói (Android giữ thanh toán).
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

  if (failure.isPhoneRequired) {
    AppToast.show(
      context,
      message: failure.message,
      type: AppToastType.warning,
      actionLabel: 'Cập nhật SĐT →',
      onAction: () => context.push(_profileEditRoute),
    );
    return true;
  }

  if (failure.isPropertyLimitReached) {
    AppToast.show(
      context,
      message: failure.message,
      type: AppToastType.warning,
      actionLabel: 'Liên hệ hỗ trợ →',
      onAction: () => context.push('/profile/help'),
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

/// Pre-flight (v1.41): OWNER phải có SĐT trước khi đăng/sửa cơ sở hoặc mời SALE
/// — BE trả 403 `PHONE_REQUIRED` nếu thiếu. Chặn chủ động phía client để tránh
/// round-trip 403 + dẫn thẳng user sang màn cập nhật hồ sơ.
///
/// Trả `true` khi đã có SĐT (cho phép tiếp tục thao tác). Trả `false` khi thiếu
/// SĐT → đã hiện dialog nhắc cập nhật, caller nên dừng.
///
/// Chỉ áp cho OWNER (ADMIN bỏ qua; SALE bị route guard chặn các thao tác này).
Future<bool> ensureOwnerHasPhone(
  BuildContext context,
  UserModel user,
) async {
  if (!user.isOwner || user.hasPhone) return true;

  final goUpdate = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cần số điện thoại'),
      content: const Text(
        'Vui lòng cập nhật số điện thoại trong hồ sơ trước khi đăng/sửa cơ sở '
        'hoặc mời nhân viên. Khách cần SĐT để liên hệ đặt phòng.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Cập nhật ngay'),
        ),
      ],
    ),
  );

  if (goUpdate == true && context.mounted) {
    context.push(_profileEditRoute);
  }
  return false;
}

/// Pre-flight (BE §3.3): OWNER phải có **tài khoản nhận tiền đã ADMIN duyệt**
/// (`bankStatus='approved'`) trước khi đăng cơ sở — đây là TK để BE sinh VietQR
/// cho khách trả cọc. Chặn chủ động phía client + dẫn sang màn khai báo.
///
/// Trả `true` khi đã có bank approved (cho phép tiếp tục). Trả `false` khi
/// thiếu/pending/rejected → đã hiện dialog nhắc, caller nên dừng.
///
/// Chỉ áp cho OWNER (ADMIN bỏ qua; SALE bị route guard chặn tạo cơ sở).
Future<bool> ensureBankForPropertyCreate(
  BuildContext context,
  UserModel user,
) async {
  if (!user.isOwner || user.hasApprovedBank) return true;

  final (title, content) = user.isBankPending
      ? (
          'Đang chờ duyệt tài khoản',
          'Tài khoản nhận tiền của bạn đang chờ quản trị viên duyệt. Sau khi '
              'được duyệt bạn mới đăng được cơ sở.',
        )
      : (
          'Cần tài khoản nhận tiền',
          'Bạn cần khai báo tài khoản ngân hàng nhận tiền (đã được duyệt) '
              'trước khi đăng cơ sở, để khách chuyển khoản đặt cọc.',
        );

  final goBank = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(user.isBankPending ? 'Xem trạng thái' : 'Khai báo ngay'),
        ),
      ],
    ),
  );

  if (goBank == true && context.mounted) {
    context.push('/profile/bank-account');
  }
  return false;
}
