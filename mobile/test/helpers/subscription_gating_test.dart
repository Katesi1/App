import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/room_entitlement.dart';
import 'package:mobile/core/utils/staff_entitlement.dart';
import 'package:mobile/core/utils/subscription_gating.dart';
import 'package:mobile/data/models/user_model.dart';

void main() {
  UserModel owner({
    String planId = 'rooms_5',
    String status = 'active',
    String kyc = 'approved',
    bool kycBypass = false,
    String? frozenReason,
  }) =>
      UserModel(
        id: 'o1',
        name: 'Owner',
        phone: '0900000000',
        role: 1,
        kycStatus: kyc,
        kycBypass: kycBypass,
        subscriptionPlanId: planId,
        subscriptionStatus: frozenReason != null ? 'frozen' : status,
        subscriptionFrozenReason: frozenReason,
      );

  group('StaffEntitlement — khớp BE STAFF_LIMIT_BY_PLAN', () {
    test('mapping planId → maxSlots', () {
      expect(StaffEntitlement.maxSlotsForPlanId('rooms_1'), 0);
      expect(StaffEntitlement.maxSlotsForPlanId('rooms_5'), 3);
      expect(StaffEntitlement.maxSlotsForPlanId('rooms_20'), isNull);
      expect(StaffEntitlement.maxSlotsForPlanId(null), 0);
      expect(StaffEntitlement.maxSlotsForPlanId('unknown'), 0);
    });
  });

  group('RoomEntitlement — khớp BE maxRooms', () {
    test('mapping planId → maxRooms', () {
      expect(RoomEntitlement.maxRoomsForPlanId('rooms_1'), 1);
      expect(RoomEntitlement.maxRoomsForPlanId('rooms_5'), 5);
      expect(RoomEntitlement.maxRoomsForPlanId('enterprise'), isNull);
    });

    test('canAddRooms respects limit', () {
      expect(
        RoomEntitlement.canAddRooms(
          planId: 'rooms_1',
          currentRoomCount: 1,
        ),
        isFalse,
      );
      expect(
        RoomEntitlement.canAddRooms(
          planId: 'rooms_5',
          currentRoomCount: 4,
        ),
        isTrue,
      );
    });
  });

  group('SubscriptionGating', () {
    test('frozen blocks invite and purchase', () {
      final u = owner(frozenReason: 'Vi phạm chính sách');
      expect(u.isSubscriptionFrozen, isTrue);
      expect(SubscriptionGating.canInviteStaff(u), isFalse);
      expect(SubscriptionGating.canInitiateFirstPurchase(u), isFalse);
      expect(SubscriptionGating.canRenewOrUpgrade(u), isFalse);
    });

    test('KYC required for first purchase unless bypass', () {
      final noKyc = owner(kyc: 'none', status: 'none');
      expect(SubscriptionGating.canInitiateFirstPurchase(noKyc), isFalse);

      final bypass = owner(kyc: 'none', status: 'none', kycBypass: true);
      expect(SubscriptionGating.canInitiateFirstPurchase(bypass), isTrue);
    });

    test('past_due blocks staff invite', () {
      final u = owner(status: 'past_due');
      expect(SubscriptionGating.canInviteStaff(u), isFalse);
      expect(u.isSubscriptionPastDueEffective, isTrue);
    });

    test('expired treated as past_due effective', () {
      final u = owner(status: 'expired');
      expect(u.isSubscriptionPastDueEffective, isTrue);
    });

    test('Starter trial can invite', () {
      final u = owner(planId: 'rooms_5', status: 'trial');
      expect(SubscriptionGating.canInviteStaff(u), isTrue);
    });
  });
}
