import '../../data/models/user_model.dart';
import 'staff_entitlement.dart';

/// Mirror rule gating subscription/payment/staff từ BE.
class SubscriptionGating {
  SubscriptionGating._();

  /// `expired` được coi như `past_due` trên UI.
  static bool isPastDueEffective(UserModel user) =>
      user.isSubscriptionPastDue || user.isSubscriptionExpired;

  static bool canInitiateFirstPurchase(UserModel user) {
    if (user.isSubscriptionFrozen) return false;
    if (!user.isOwner) return true;
    return user.isKycApproved || user.kycBypass;
  }

  static bool canRenewOrUpgrade(UserModel user) => !user.isSubscriptionFrozen;

  static bool canOpenPlanPicker(UserModel user) => !user.isSubscriptionFrozen;

  /// BE: POST /staff/invites cần trial|active + plan cho phép + KYC (trừ bypass).
  static bool canInviteStaff(UserModel user) {
    if (!user.isOwner || user.isSubscriptionFrozen) return false;
    if (!user.isKycApproved && !user.kycBypass) return false;
    if (!user.isInTrial && !user.isSubscriptionActive) return false;
    return StaffEntitlement.allowsInvite(user.subscriptionPlanId);
  }

  static String frozenBannerMessage(UserModel user) {
    final reason = user.subscriptionFrozenReason?.trim();
    if (reason != null && reason.isNotEmpty) {
      return reason;
    }
    return 'Tài khoản tạm khoá. Vui lòng liên hệ hỗ trợ.';
  }

  static String staffInviteBlockReason(UserModel user) {
    if (!user.isOwner) return 'Chỉ chủ homestay mới mời được nhân viên';
    if (user.isSubscriptionFrozen) return frozenBannerMessage(user);
    if (!user.isKycApproved && !user.kycBypass) {
      return 'Cần hoàn thành xác minh danh tính (KYC) trước khi mời nhân viên.';
    }
    if (!user.isInTrial && !user.isSubscriptionActive) {
      if (user.subscriptionStatus == 'none') {
        return 'Bạn cần mua gói subscription để mời nhân viên.';
      }
      if (isPastDueEffective(user)) {
        return 'Gói đang quá hạn thanh toán. Gia hạn để tiếp tục mời nhân viên.';
      }
      if (user.isSubscriptionCancelled) {
        return 'Gói đã huỷ. Mua lại gói để mời nhân viên.';
      }
      return 'Gói subscription chưa kích hoạt (cần trial hoặc active).';
    }
    final slots = StaffEntitlement.maxSlotsForPlanId(user.subscriptionPlanId);
    if (slots == 0) {
      return 'Gói ${user.subscriptionPlanLabel} không hỗ trợ mời nhân viên. '
          'Nâng cấp lên ${StaffEntitlement.minPlanLabel} '
          '(tối đa 3 nhân viên) hoặc cao hơn.';
    }
    return '';
  }
}
