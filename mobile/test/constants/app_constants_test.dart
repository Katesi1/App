import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';

void main() {
  group('UserRole', () {
    group('value', () {
      test('returns correct int values', () {
        expect(UserRole.admin.value, 0);
        expect(UserRole.owner.value, 1);
        expect(UserRole.sale.value, 2);
      });
    });

    group('label', () {
      test('returns Vietnamese labels', () {
        expect(UserRole.admin.label, 'Admin');
        expect(UserRole.owner.label, 'Chủ nhà');
        expect(UserRole.sale.label, 'Sale');
      });
    });

    group('isManagement', () {
      test('all roles are management', () {
        expect(UserRole.admin.isManagement, true);
        expect(UserRole.owner.isManagement, true);
        expect(UserRole.sale.isManagement, true);
      });
    });

    group('fromInt', () {
      test('parses all roles', () {
        expect(UserRoleExtension.fromInt(0), UserRole.admin);
        expect(UserRoleExtension.fromInt(1), UserRole.owner);
        expect(UserRoleExtension.fromInt(2), UserRole.sale);
      });

      test('defaults to owner for unknown values', () {
        expect(UserRoleExtension.fromInt(99), UserRole.owner);
        expect(UserRoleExtension.fromInt(-1), UserRole.owner);
      });
    });

    group('registrableRoles', () {
      test('contains owner and sale', () {
        expect(UserRoleExtension.registrableRoles,
            containsAll([UserRole.owner, UserRole.sale]));
      });

      test('does NOT contain admin', () {
        expect(UserRoleExtension.registrableRoles,
            isNot(contains(UserRole.admin)));
      });
    });
  });

  group('BookingStatus', () {
    group('value', () {
      test('returns correct int values', () {
        expect(BookingStatus.hold.value, 0);
        expect(BookingStatus.confirmed.value, 1);
        expect(BookingStatus.cancelled.value, 2);
        expect(BookingStatus.completed.value, 3);
      });
    });

    group('label', () {
      test('returns Vietnamese labels', () {
        expect(BookingStatus.hold.label, 'Đang giữ');
        expect(BookingStatus.confirmed.label, 'Đã xác nhận');
        expect(BookingStatus.cancelled.label, 'Đã huỷ');
        expect(BookingStatus.completed.label, 'Hoàn thành');
      });
    });

    group('fromInt', () {
      test('parses all statuses', () {
        expect(BookingStatusExtension.fromInt(0), BookingStatus.hold);
        expect(BookingStatusExtension.fromInt(1), BookingStatus.confirmed);
        expect(BookingStatusExtension.fromInt(2), BookingStatus.cancelled);
        expect(BookingStatusExtension.fromInt(3), BookingStatus.completed);
      });

      test('defaults to hold for unknown', () {
        expect(BookingStatusExtension.fromInt(99), BookingStatus.hold);
      });
    });
  });
}
