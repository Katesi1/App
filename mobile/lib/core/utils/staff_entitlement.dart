import '../config/app_config.dart';

/// Staff (SALE) invite quota per subscription plan — **frontend mirror** of the
/// backend `StaffEntitlement` (`API_SPEC_FULL.md` §11.1.1).
///
/// Backend enforces these limits server-side on `POST /staff/invites`; this is
/// a UX pre-check so the owner sees the reason before hitting a 403/409. When
/// the quota table changes, update **both** this file and the backend.
///
/// | planId    | Tên gói   | Tối đa SALE      |
/// |-----------|-----------|------------------|
/// | rooms_1   | Mini      | 0 (không cho mời)|
/// | rooms_5   | Starter   | 3                |
/// | rooms_10  | Standard  | 3                |
/// | rooms_20  | Pro       | không giới hạn   |
/// | rooms_50  | Business  | không giới hạn   |
/// | enterprise| Enterprise| không giới hạn   |
///
/// Ngoại lệ **trial im lặng**: OWNER vừa đăng ký + KYC duyệt nhưng chưa mua gói
/// (`planId == null`, `subscriptionStatus == 'trial'`) vẫn được cấp
/// [trialMaxSaleStaff] slot — mirror BE `src/common/staff-entitlement.ts`.
class StaffEntitlement {
  StaffEntitlement._();

  /// Active subscription states that may invite staff (`trial` | `active`).
  /// `past_due | cancelled | expired | frozen | none` are all blocked.
  static const Set<String> _activeStatuses = {'trial', 'active'};

  /// SALE slot được cấp cho trial im lặng (chưa gắn gói). Mirror BE
  /// `kTrialMaxSaleStaff`.
  static const int trialMaxSaleStaff = 1;

  /// BE `code` cho lỗi 409 đầy slot (`staff.staffSlotLimitReached`).
  static const String slotLimitCode = 'staff.staffSlotLimitReached';

  /// Max SALE slots a plan allows. `null` = unlimited. Unknown/missing plan = 0.
  static int? maxSlotsFor(String? planId) => switch (planId) {
        'rooms_1' || 'mini' => 0,
        'rooms_5' || 'starter' => 3,
        'rooms_10' || 'standard' => 3,
        'rooms_20' || 'pro' || 'professional' => null,
        'rooms_50' || 'business' => null,
        'enterprise' => null,
        _ => 0,
      };

  /// Số slot SALE thực tế — trial im lặng (chưa gắn gói) vẫn được
  /// [trialMaxSaleStaff]; còn lại theo quota của gói. Mirror BE
  /// `getEffectiveMaxSaleStaff(planId, subscriptionStatus)`.
  static int? effectiveMaxSlotsFor(String? planId, String subscriptionStatus) {
    if (planId == null && subscriptionStatus == 'trial') {
      return trialMaxSaleStaff;
    }
    return maxSlotsFor(planId);
  }

  /// Whether the plan grants any invite quota at all (`> 0` or unlimited).
  static bool planAllowsInvite(String? planId) {
    final max = maxSlotsFor(planId);
    return max == null || max > 0;
  }

  /// Message lỗi hiển thị khi gửi lời mời thất bại. Trên iOS (App Store
  /// 3.1.1) KHÔNG được nhắc "nâng cấp / mua gói" → thay lỗi đầy slot bằng
  /// copy trung tính. Nền tảng khác giữ nguyên message tiếng Việt từ BE.
  static String inviteErrorMessage({
    required String? code,
    required String beMessage,
  }) {
    final normalized = code?.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final isSlotLimit = normalized?.contains('slotlimitreached') ?? false;
    if (AppConfig.hidePaidUpgradeUI && isSlotLimit) {
      return 'Bạn đã đạt số nhân viên tối đa cho tài khoản hiện tại.';
    }
    return beMessage;
  }

  /// Evaluate whether the signed-in user can send another staff invite now.
  /// Mirrors the 5 backend conditions; ADMIN bypasses all of them.
  ///
  /// [usedSlots] = active SALE staff + pending (not-yet-expired) invites.
  /// [enforceSlotLimit] should be `false` while those counts are still loading
  /// so we don't show a false "limit reached" — the server is the source of
  /// truth and will reject with the precise message if needed.
  static InviteEligibility evaluate({
    required bool isAdmin,
    required bool isOwner,
    required bool isKycApproved,
    required String subscriptionStatus,
    required String? planId,
    required int usedSlots,
    bool enforceSlotLimit = true,
  }) {
    // ADMIN bypasses every check (seed / manual fix).
    if (isAdmin) return const InviteEligibility.allowed();

    if (!isOwner) {
      return const InviteEligibility.blocked(
        InviteBlockReason.notOwner,
        'Chỉ chủ homestay (OWNER) mới mời được nhân viên.',
      );
    }
    if (!isKycApproved) {
      return const InviteEligibility.blocked(
        InviteBlockReason.kycRequired,
        'Hoàn tất xác minh danh tính (KYC) để bắt đầu sử dụng và mời nhân viên.',
      );
    }

    // Subscription state gate — only `trial`/`active` may invite (xem bảng §10).
    if (!_activeStatuses.contains(subscriptionStatus)) {
      final reason = switch (subscriptionStatus) {
        'past_due' => InviteBlockReason.subscriptionPastDue,
        'frozen' => InviteBlockReason.subscriptionFrozen,
        _ =>
          InviteBlockReason.subscriptionInactive, // none | cancelled | expired
      };
      final message = switch (reason) {
        InviteBlockReason.subscriptionPastDue =>
          'Gói của bạn đang quá hạn thanh toán. Gia hạn để tiếp tục mời nhân viên.',
        InviteBlockReason.subscriptionFrozen =>
          'Tài khoản đang tạm khoá. Liên hệ hỗ trợ để mở lại trước khi mời nhân viên.',
        _ =>
          'Bạn chưa có gói dịch vụ đang hoạt động. Mua gói để bắt đầu mời nhân viên.',
      };
      return InviteEligibility.blocked(reason, message);
    }

    // Trial im lặng (chưa gắn gói) vẫn được cấp [trialMaxSaleStaff] slot.
    final max = effectiveMaxSlotsFor(planId, subscriptionStatus);
    final isTrialOnly = planId == null && subscriptionStatus == 'trial';
    if (max == 0) {
      return InviteEligibility.blocked(
        InviteBlockReason.planNotAllowed,
        'Gói ${_planLabel(planId)} chưa hỗ trợ mời nhân viên. '
        'Nâng cấp lên Starter trở lên để thêm nhân viên SALE.',
      );
    }
    if (enforceSlotLimit && max != null && usedSlots >= max) {
      final message = isTrialOnly
          ? 'Bản dùng thử chỉ cho phép $max nhân viên. '
              'Nâng cấp lên gói Starter để mời thêm nhân viên.'
          : 'Đã dùng hết $max lượt nhân viên của gói ${_planLabel(planId)}. '
              'Nâng cấp lên Pro để mời không giới hạn.';
      return InviteEligibility.blocked(
        InviteBlockReason.slotLimitReached,
        message,
      );
    }

    return InviteEligibility.allowed(
      remaining: max == null ? null : (max - usedSlots).clamp(0, max),
    );
  }

  /// Short display name for a plan id (no coupling to the verify `Tier` enum).
  static String _planLabel(String? planId) => switch (planId) {
        'rooms_1' || 'mini' => 'Mini',
        'rooms_5' || 'starter' => 'Starter',
        'rooms_10' || 'standard' => 'Standard',
        'rooms_20' || 'pro' || 'professional' => 'Pro',
        'rooms_50' || 'business' => 'Business',
        'enterprise' => 'Enterprise',
        _ => 'hiện tại',
      };
}

/// Why a user can't invite staff — lets the UI pick the right CTA + copy.
enum InviteBlockReason {
  /// Not an OWNER (SALE/CUSTOMER).
  notOwner,

  /// KYC not approved yet → must verify identity.
  kycRequired,

  /// No active subscription (none/cancelled/expired) → must buy a plan.
  subscriptionInactive,

  /// Subscription past due → must renew.
  subscriptionPastDue,

  /// Account frozen → must contact support.
  subscriptionFrozen,

  /// Current plan (Mini) grants 0 slots → must upgrade.
  planNotAllowed,

  /// Finite-plan quota used up → must upgrade for more slots.
  slotLimitReached,
}

/// Result of [StaffEntitlement.evaluate].
class InviteEligibility {
  /// Whether the user may send an invite right now.
  final bool allowed;

  /// Why invites are blocked (null when [allowed]).
  final InviteBlockReason? blockReason;

  /// Vietnamese reason shown to the user when [allowed] is `false`.
  final String? reason;

  /// Remaining SALE slots — `null` when unlimited or when blocked.
  final int? remaining;

  const InviteEligibility.allowed({this.remaining})
      : allowed = true,
        blockReason = null,
        reason = null;

  const InviteEligibility.blocked(this.blockReason, this.reason)
      : allowed = false,
        remaining = null;

  /// `true` when the plan grants unlimited slots (allowed + no remaining cap).
  bool get isUnlimited => allowed && remaining == null;

  /// Whether the fix is buying/upgrading a plan — i.e. the CTA points to the
  /// plan picker.
  bool get isPlanUpgradeFix =>
      blockReason == InviteBlockReason.subscriptionInactive ||
      blockReason == InviteBlockReason.planNotAllowed ||
      blockReason == InviteBlockReason.slotLimitReached;

  /// Whether the upsell should surface the "plans that unlock staff" table.
  /// Includes [InviteBlockReason.kycRequired] so a brand-new owner (no KYC, no
  /// plan) still learns they'll need Starter+ to add staff.
  bool get showsPlanOptions =>
      isPlanUpgradeFix || blockReason == InviteBlockReason.kycRequired;
}
