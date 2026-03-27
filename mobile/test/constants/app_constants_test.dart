import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';

void main() {
  group('UserRole', () {
    group('value', () {
      test('returns uppercase string', () {
        expect(UserRole.admin.value, 'ADMIN');
        expect(UserRole.staff.value, 'STAFF');
        expect(UserRole.customer.value, 'CUSTOMER');
      });
    });

    group('label', () {
      test('returns Vietnamese labels', () {
        expect(UserRole.admin.label, 'Admin');
        expect(UserRole.staff.label, 'Nhân viên');
        expect(UserRole.customer.label, 'Khách hàng');
      });
    });

    group('isManagement', () {
      test('admin is management', () {
        expect(UserRole.admin.isManagement, true);
      });

      test('staff is management', () {
        expect(UserRole.staff.isManagement, true);
      });

      test('customer is NOT management', () {
        expect(UserRole.customer.isManagement, false);
      });
    });

    group('fromString', () {
      test('parses new roles', () {
        expect(UserRoleExtension.fromString('ADMIN'), UserRole.admin);
        expect(UserRoleExtension.fromString('STAFF'), UserRole.staff);
        expect(
            UserRoleExtension.fromString('CUSTOMER'), UserRole.customer);
      });

      test('case insensitive', () {
        expect(UserRoleExtension.fromString('admin'), UserRole.admin);
        expect(UserRoleExtension.fromString('Staff'), UserRole.staff);
      });

      test('migrates legacy roles to STAFF', () {
        expect(UserRoleExtension.fromString('OWNER'), UserRole.staff);
        expect(UserRoleExtension.fromString('SALE'), UserRole.staff);
      });

      test('defaults to customer for unknown', () {
        expect(
            UserRoleExtension.fromString('UNKNOWN'), UserRole.customer);
        expect(UserRoleExtension.fromString(''), UserRole.customer);
      });
    });

    group('registrableRoles', () {
      test('contains staff and customer only', () {
        expect(UserRoleExtension.registrableRoles,
            [UserRole.staff, UserRole.customer]);
      });

      test('does NOT contain admin', () {
        expect(UserRoleExtension.registrableRoles,
            isNot(contains(UserRole.admin)));
      });
    });
  });

  group('BookingStatus', () {
    group('value', () {
      test('returns uppercase string', () {
        expect(BookingStatus.hold.value, 'HOLD');
        expect(BookingStatus.confirmed.value, 'CONFIRMED');
        expect(BookingStatus.cancelled.value, 'CANCELLED');
        expect(BookingStatus.completed.value, 'COMPLETED');
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

    group('fromString', () {
      test('parses all statuses', () {
        expect(BookingStatusExtension.fromString('HOLD'),
            BookingStatus.hold);
        expect(BookingStatusExtension.fromString('CONFIRMED'),
            BookingStatus.confirmed);
        expect(BookingStatusExtension.fromString('CANCELLED'),
            BookingStatus.cancelled);
        expect(BookingStatusExtension.fromString('COMPLETED'),
            BookingStatus.completed);
      });

      test('defaults to hold for unknown', () {
        expect(BookingStatusExtension.fromString('UNKNOWN'),
            BookingStatus.hold);
      });
    });
  });
}
