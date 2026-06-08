import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/staff_entitlement.dart';

void main() {
  group('StaffEntitlement.maxSlotsFor', () {
    test('returns plan quotas (null = unlimited)', () {
      expect(StaffEntitlement.maxSlotsFor('rooms_1'), 0);
      expect(StaffEntitlement.maxSlotsFor('rooms_5'), 3);
      expect(StaffEntitlement.maxSlotsFor('rooms_10'), 3);
      expect(StaffEntitlement.maxSlotsFor('rooms_20'), isNull);
      expect(StaffEntitlement.maxSlotsFor('rooms_50'), isNull);
      expect(StaffEntitlement.maxSlotsFor('enterprise'), isNull);
    });

    test('accepts legacy aliases', () {
      expect(StaffEntitlement.maxSlotsFor('starter'), 3);
      expect(StaffEntitlement.maxSlotsFor('professional'), isNull);
    });

    test('unknown / null plan = 0 slots', () {
      expect(StaffEntitlement.maxSlotsFor(null), 0);
      expect(StaffEntitlement.maxSlotsFor('???'), 0);
    });
  });

  group('StaffEntitlement.evaluate', () {
    InviteEligibility eval({
      bool isAdmin = false,
      bool isOwner = true,
      bool isKycApproved = true,
      String status = 'active',
      String? planId = 'rooms_5',
      int usedSlots = 0,
      bool enforceSlotLimit = true,
    }) =>
        StaffEntitlement.evaluate(
          isAdmin: isAdmin,
          isOwner: isOwner,
          isKycApproved: isKycApproved,
          subscriptionStatus: status,
          planId: planId,
          usedSlots: usedSlots,
          enforceSlotLimit: enforceSlotLimit,
        );

    test('admin bypasses every check', () {
      final r = eval(
        isAdmin: true,
        isOwner: false,
        isKycApproved: false,
        status: 'none',
        planId: 'rooms_1',
        usedSlots: 99,
      );
      expect(r.allowed, isTrue);
      expect(r.isUnlimited, isTrue);
    });

    test('blocks non-owner', () {
      expect(eval(isOwner: false).allowed, isFalse);
    });

    test('blocks when KYC not approved', () {
      expect(eval(isKycApproved: false).allowed, isFalse);
    });

    test('blocks inactive subscription', () {
      for (final s in ['none', 'past_due', 'cancelled', 'expired', 'frozen']) {
        expect(eval(status: s).allowed, isFalse, reason: s);
      }
      expect(eval(status: 'trial').allowed, isTrue);
      expect(eval(status: 'active').allowed, isTrue);
    });

    test('Mini plan never allows invites', () {
      expect(eval(planId: 'rooms_1').allowed, isFalse);
    });

    test('finite plan: remaining decreases, blocks at limit', () {
      expect(eval(planId: 'rooms_5', usedSlots: 0).remaining, 3);
      expect(eval(planId: 'rooms_5', usedSlots: 2).remaining, 1);
      expect(eval(planId: 'rooms_5', usedSlots: 3).allowed, isFalse);
    });

    test('does not block on limit while counts unknown', () {
      final r = eval(planId: 'rooms_5', usedSlots: 5, enforceSlotLimit: false);
      expect(r.allowed, isTrue);
    });

    test('unlimited plan has null remaining', () {
      final r = eval(planId: 'rooms_20', usedSlots: 100);
      expect(r.allowed, isTrue);
      expect(r.isUnlimited, isTrue);
    });

    test('sets the right block reason per case', () {
      expect(eval(isOwner: false).blockReason, InviteBlockReason.notOwner);
      expect(eval(isKycApproved: false).blockReason,
          InviteBlockReason.kycRequired);
      expect(eval(status: 'none').blockReason,
          InviteBlockReason.subscriptionInactive);
      expect(eval(status: 'cancelled').blockReason,
          InviteBlockReason.subscriptionInactive);
      expect(eval(status: 'past_due').blockReason,
          InviteBlockReason.subscriptionPastDue);
      expect(eval(status: 'frozen').blockReason,
          InviteBlockReason.subscriptionFrozen);
      expect(eval(planId: 'rooms_1').blockReason,
          InviteBlockReason.planNotAllowed);
      expect(eval(planId: 'rooms_5', usedSlots: 3).blockReason,
          InviteBlockReason.slotLimitReached);
    });

    test('isPlanUpgradeFix only for buy/upgrade cases', () {
      expect(eval(status: 'none').isPlanUpgradeFix, isTrue);
      expect(eval(planId: 'rooms_1').isPlanUpgradeFix, isTrue);
      expect(eval(planId: 'rooms_5', usedSlots: 3).isPlanUpgradeFix, isTrue);
      expect(eval(isKycApproved: false).isPlanUpgradeFix, isFalse);
      expect(eval(status: 'frozen').isPlanUpgradeFix, isFalse);
    });
  });
}
