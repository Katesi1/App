import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/staff_entitlement.dart';
import 'package:mobile/data/models/user_model.dart';

void main() {
  group('StaffEntitlement', () {
    test('Mini và starter_test không có slot nhân viên', () {
      expect(StaffEntitlement.maxSlotsForPlanId('rooms_1'), 0);
      expect(StaffEntitlement.maxSlotsForPlanId('mini'), 0);
      expect(StaffEntitlement.maxSlotsForPlanId('starter_test'), 0);
      expect(StaffEntitlement.allowsInvite('rooms_1'), isFalse);
    });

    test('Starter và Standard giới hạn 3 nhân viên', () {
      expect(StaffEntitlement.maxSlotsForPlanId('rooms_5'), 3);
      expect(StaffEntitlement.maxSlotsForPlanId('rooms_10'), 3);
      expect(StaffEntitlement.allowsInvite('rooms_5'), isTrue);
    });

    test('Pro trở lên không giới hạn', () {
      expect(StaffEntitlement.maxSlotsForPlanId('rooms_20'), isNull);
      expect(StaffEntitlement.maxSlotsForPlanId('enterprise'), isNull);
      expect(StaffEntitlement.allowsInvite('rooms_20'), isTrue);
    });
  });

  group('UserModel staff invite', () {
    UserModel owner({
      String planId = 'rooms_1',
      String status = 'active',
      String kycStatus = 'approved',
    }) =>
        UserModel(
          id: 'o1',
          name: 'Owner',
          phone: '0900000000',
          role: 1,
          kycStatus: kycStatus,
          subscriptionPlanId: planId,
          subscriptionStatus: status,
        );

    test('Mini active không được mời nhân viên', () {
      final user = owner();
      expect(user.canInviteStaff, isFalse);
      expect(user.staffInviteBlockReason, contains('Mini'));
      expect(user.staffInviteBlockReason, contains('Starter'));
    });

    test('Starter trial được mời nhân viên', () {
      final user = owner(planId: 'rooms_5', status: 'trial');
      expect(user.canInviteStaff, isTrue);
      expect(user.maxStaffInviteSlots, 3);
      expect(user.staffInviteBlockReason, isEmpty);
    });

    test('Chưa có gói bị khóa', () {
      final user = owner(status: 'none');
      expect(user.canInviteStaff, isFalse);
      expect(user.staffInviteBlockReason, contains('mua gói'));
    });
  });
}
