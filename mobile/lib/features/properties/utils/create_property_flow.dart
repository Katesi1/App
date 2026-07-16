import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/property_room_counter.dart';
import '../../../shared/widgets/feature_locked.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../verify/controllers/verify_flow_controller.dart';
import '../../verify/views/paywall_modal.dart';
import '../controllers/property_controller.dart';

/// Luồng "Thêm phòng" dùng chung (bottom nav + màn quản lý cơ sở).
///
/// Thứ tự cổng cho OWNER: (0) SĐT → (1) KYC → (2) bank đã duyệt → quota gói,
/// rồi mở form `/properties/new`. ADMIN/SALE bỏ qua các cổng (SALE bị route
/// guard chặn tạo — chỉ ADMIN tạo thẳng).
Future<void> startCreatePropertyFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = ref.read(currentUserProvider);
  final verifyState = ref.read(verifyFlowControllerProvider);

  if (user == null) return;

  // v1.41: OWNER phải có SĐT trước khi đăng cơ sở (BE 403 PHONE_REQUIRED).
  if (!await ensureOwnerHasPhone(context, user)) return;
  if (!context.mounted) return;

  if (user.isOwner && !user.needsKyc) {
    // Cổng bank (BE §3.3): OWNER phải có tài khoản nhận tiền đã duyệt.
    if (!await ensureBankForPropertyCreate(context, user)) return;
    if (!context.mounted) return;
    try {
      final homestays = await ref.read(homestayListProvider(true).future);
      final count = PropertyRoomCounter.fromHomestays(homestays);
      if (!user.canAddMoreRooms(count)) {
        if (context.mounted) {
          AppSnackBar.error(context, user.roomQuotaAtLimitMessage(count));
        }
        return;
      }
    } catch (_) {}
    if (context.mounted) context.push('/properties/new');
    return;
  }

  if (!user.isOwner) {
    context.push('/properties/new');
    return;
  }

  // Source of truth: user.kycStatus từ /auth/profile.
  if (user.isKycPending) {
    context.push('/verify/pending');
    return;
  }
  if (user.isKycRejected) {
    context.push('/verify/rejected');
    return;
  }

  final ok = await showPaywallModal(context);
  if (ok == true && context.mounted) {
    final step = verifyState.kycCurrentStep;
    final route = switch (step) {
      2 => '/verify/cccd-back',
      3 => '/verify/selfie',
      4 => '/verify/pending',
      _ => '/verify/cccd-front',
    };
    if (context.mounted) context.push(route);
  }
}
