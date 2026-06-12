import '../../data/models/user_model.dart';
import 'staff_entitlement.dart';

/// Lý do mời nhân viên bị chặn — để UI chọn đúng CTA (KYC vs mua gói).
enum StaffInviteBlock {
  /// Được phép mời.
  none,

  /// Không phải OWNER.
  notOwner,

  /// Tài khoản bị đóng băng.
  frozen,

  /// Chưa hoàn thành KYC (đã có gói/trial) → CTA xác minh, KHÔNG phải mua gói.
  kyc,

  /// Cần mua/nâng gói (chưa có subscription, hết hạn, hoặc gói không hỗ trợ mời).
  plan,
}

/// Mirror rule gating subscription/payment/staff từ BE.
class SubscriptionGating {
  SubscriptionGating._();

  /// Số slot SALE mặc định trong silent trial (BE cho mời 1 SALE — API_SPEC
  /// §2A.5: "tạo property, mời 1 SALE").
  static const int trialDefaultStaffSlots = 1;

  /// `expired` được coi như `past_due` trên UI.
  static bool isPastDueEffective(UserModel user) =>
      user.isSubscriptionPastDue || user.isSubscriptionExpired;

  /// Silent trial v1.12: OWNER mới đăng ký được BE cấp trial 60 ngày nhưng
  /// CHƯA gắn `subscriptionPlanId`. Trong giai đoạn này quota theo "trial
  /// default" (rooms để BE gate, staff = 1) thay vì theo plan (planId null →
  /// pure util trả 0 → sẽ chặn nhầm).
  static bool isSilentTrial(UserModel user) =>
      user.isInTrial &&
      (user.subscriptionPlanId == null || user.subscriptionPlanId!.isEmpty);

  static bool canInitiateFirstPurchase(UserModel user) {
    if (user.isSubscriptionFrozen) return false;
    if (!user.isOwner) return true;
    return user.isKycApproved || user.kycBypass;
  }

  static bool canRenewOrUpgrade(UserModel user) => !user.isSubscriptionFrozen;

  static bool canOpenPlanPicker(UserModel user) => !user.isSubscriptionFrozen;

  /// BE: POST /staff/invites cần trial|active + plan cho phép + KYC (trừ bypass).
  static bool canInviteStaff(UserModel user) =>
      staffInviteBlock(user) == StaffInviteBlock.none;

  /// Phân loại lý do chặn mời nhân viên (nguồn sự thật cho cả banner + FAB).
  static StaffInviteBlock staffInviteBlock(UserModel user) {
    if (!user.isOwner) return StaffInviteBlock.notOwner;
    if (user.isSubscriptionFrozen) return StaffInviteBlock.frozen;
    if (!user.isKycApproved && !user.kycBypass) return StaffInviteBlock.kyc;
    // Chưa có subscription / hết hạn → cần mua gói.
    if (!user.isInTrial && !user.isSubscriptionActive) {
      return StaffInviteBlock.plan;
    }
    // Silent trial chưa gắn plan → BE cho mời 1 SALE (không theo plan quota).
    if (isSilentTrial(user)) return StaffInviteBlock.none;
    // Gói không hỗ trợ mời (Mini) → cần nâng gói.
    if (!StaffEntitlement.allowsInvite(user.subscriptionPlanId)) {
      return StaffInviteBlock.plan;
    }
    return StaffInviteBlock.none;
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
    // Silent trial → được mời (BE cap 1 SALE) → không có lý do chặn.
    if (isSilentTrial(user)) return '';
    final slots = StaffEntitlement.maxSlotsForPlanId(user.subscriptionPlanId);
    if (slots == 0) {
      return 'Gói ${user.subscriptionPlanLabel} không hỗ trợ mời nhân viên. '
          'Nâng cấp lên ${StaffEntitlement.minPlanLabel} '
          '(tối đa 3 nhân viên) hoặc cao hơn.';
    }
    return '';
  }
}
