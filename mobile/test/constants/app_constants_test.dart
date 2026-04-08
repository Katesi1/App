import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';

void main() {
  group('UserRole', () {
    group('value', () {
      test('returns correct int values', () {
        expect(UserRole.admin.value, 0);
        expect(UserRole.owner.value, 1);
        expect(UserRole.sale.value, 2);
        expect(UserRole.customer.value, 3);
      });
    });

    group('label', () {
      test('returns Vietnamese labels', () {
        expect(UserRole.admin.label, 'Admin');
        expect(UserRole.owner.label, 'Chủ nhà');
        expect(UserRole.sale.label, 'Sale');
        expect(UserRole.customer.label, 'Khách hàng');
      });
    });

    group('isManagement', () {
      test('admin is management', () {
        expect(UserRole.admin.isManagement, true);
      });

      test('owner is management', () {
        expect(UserRole.owner.isManagement, true);
      });

      test('sale is management', () {
        expect(UserRole.sale.isManagement, true);
      });

      test('customer is NOT management', () {
        expect(UserRole.customer.isManagement, false);
      });
    });

    group('fromInt', () {
      test('parses all roles', () {
        expect(UserRoleExtension.fromInt(0), UserRole.admin);
        expect(UserRoleExtension.fromInt(1), UserRole.owner);
        expect(UserRoleExtension.fromInt(2), UserRole.sale);
        expect(UserRoleExtension.fromInt(3), UserRole.customer);
      });

      test('defaults to customer for unknown', () {
        expect(UserRoleExtension.fromInt(99), UserRole.customer);
        expect(UserRoleExtension.fromInt(-1), UserRole.customer);
      });
    });

    group('registrableRoles', () {
      test('contains owner, sale, and customer', () {
        expect(UserRoleExtension.registrableRoles,
            containsAll([UserRole.owner, UserRole.sale, UserRole.customer]));
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
