import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/helpers.dart';
import 'package:mobile/core/theme/app_colors.dart';

void main() {
  group('AppHelpers.roleLabel', () {
    test('returns correct labels for new roles', () {
      expect(AppHelpers.roleLabel('ADMIN'), 'Admin');
      expect(AppHelpers.roleLabel('STAFF'), 'Nhân viên');
      expect(AppHelpers.roleLabel('CUSTOMER'), 'Khách hàng');
    });

    test('handles legacy roles (migration)', () {
      expect(AppHelpers.roleLabel('OWNER'), 'Nhân viên');
      expect(AppHelpers.roleLabel('SALE'), 'Nhân viên');
    });

    test('case insensitive', () {
      expect(AppHelpers.roleLabel('admin'), 'Admin');
      expect(AppHelpers.roleLabel('staff'), 'Nhân viên');
      expect(AppHelpers.roleLabel('customer'), 'Khách hàng');
    });

    test('returns raw value for unknown role', () {
      expect(AppHelpers.roleLabel('UNKNOWN'), 'UNKNOWN');
    });

    test('handles null', () {
      expect(AppHelpers.roleLabel(null), '');
    });
  });

  group('AppHelpers.roleColor', () {
    test('returns correct colors for new roles', () {
      expect(AppHelpers.roleColor('ADMIN'), AppColors.coral);
      expect(AppHelpers.roleColor('STAFF'), AppColors.ocean);
      expect(AppHelpers.roleColor('CUSTOMER'), AppColors.teal);
    });

    test('handles legacy roles', () {
      expect(AppHelpers.roleColor('OWNER'), AppColors.ocean);
      expect(AppHelpers.roleColor('SALE'), AppColors.ocean);
    });

    test('defaults to ocean for null/unknown', () {
      expect(AppHelpers.roleColor(null), AppColors.ocean);
      expect(AppHelpers.roleColor('UNKNOWN'), AppColors.ocean);
    });
  });

  group('AppHelpers.bookingStatusColor', () {
    test('returns correct colors', () {
      expect(
          AppHelpers.bookingStatusColor('HOLD'), AppColors.hold);
      expect(AppHelpers.bookingStatusColor('CONFIRMED'),
          AppColors.confirmed);
      expect(AppHelpers.bookingStatusColor('CANCELLED'),
          AppColors.cancelled);
      expect(AppHelpers.bookingStatusColor('COMPLETED'),
          AppColors.completed);
    });

    test('defaults to primary for null/unknown', () {
      expect(
          AppHelpers.bookingStatusColor(null), AppColors.primary);
      expect(AppHelpers.bookingStatusColor('INVALID'),
          AppColors.primary);
    });
  });

  group('AppHelpers.formatPrice', () {
    test('formats millions as "tr"', () {
      expect(AppHelpers.formatPrice(1500000), '1.5tr');
      expect(AppHelpers.formatPrice(2000000), '2.0tr');
      expect(AppHelpers.formatPrice(1000000), '1.0tr');
    });

    test('formats thousands as "k"', () {
      expect(AppHelpers.formatPrice(800000), '800k');
      expect(AppHelpers.formatPrice(500000), '500k');
      expect(AppHelpers.formatPrice(50000), '50k');
    });
  });

  group('AppHelpers.formatPriceTotal', () {
    test('calculates total and formats', () {
      expect(AppHelpers.formatPriceTotal(500000, 3), '1.5tr');
      expect(AppHelpers.formatPriceTotal(800000, 1), '800k');
    });
  });

  group('AppHelpers.vietnameseDayOfWeek', () {
    test('returns correct Vietnamese day names', () {
      expect(AppHelpers.vietnameseDayOfWeek(1), 'Thứ Hai');
      expect(AppHelpers.vietnameseDayOfWeek(2), 'Thứ Ba');
      expect(AppHelpers.vietnameseDayOfWeek(3), 'Thứ Tư');
      expect(AppHelpers.vietnameseDayOfWeek(4), 'Thứ Năm');
      expect(AppHelpers.vietnameseDayOfWeek(5), 'Thứ Sáu');
      expect(AppHelpers.vietnameseDayOfWeek(6), 'Thứ Bảy');
      expect(AppHelpers.vietnameseDayOfWeek(7), 'Chủ Nhật');
    });

    test('returns empty for invalid weekday', () {
      expect(AppHelpers.vietnameseDayOfWeek(0), '');
      expect(AppHelpers.vietnameseDayOfWeek(8), '');
    });
  });
}
