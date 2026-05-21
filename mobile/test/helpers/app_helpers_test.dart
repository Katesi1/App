import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/helpers.dart';
import 'package:mobile/core/theme/app_colors.dart';

void main() {
  group('AppHelpers.roleLabel', () {
    test('returns correct labels (0=ADMIN, 1=OWNER, 2=SALE, 3=CUSTOMER)', () {
      expect(AppHelpers.roleLabel(0), 'Admin');
      expect(AppHelpers.roleLabel(1), 'Chủ nhà');
      expect(AppHelpers.roleLabel(2), 'Sale');
      expect(AppHelpers.roleLabel(3), 'Khách hàng');
    });

    test('returns empty string for unknown role', () {
      expect(AppHelpers.roleLabel(99), '');
    });

    test('handles null', () {
      expect(AppHelpers.roleLabel(null), '');
    });
  });

  group('AppHelpers.roleColor', () {
    test('returns correct colors', () {
      expect(AppHelpers.roleColor(0), AppColors.coral);
      expect(AppHelpers.roleColor(1), AppColors.amber);
      expect(AppHelpers.roleColor(2), AppColors.ocean);
      expect(AppHelpers.roleColor(3), AppColors.teal);
    });

    test('defaults to ocean for null/unknown', () {
      expect(AppHelpers.roleColor(null), AppColors.ocean);
      expect(AppHelpers.roleColor(99), AppColors.ocean);
    });
  });

  group('AppHelpers.bookingStatusColor', () {
    test('returns correct colors (0=HOLD, 1=CONFIRMED, 2=CANCELLED, 3=COMPLETED)',
        () {
      expect(AppHelpers.bookingStatusColor(0), AppColors.hold);
      expect(AppHelpers.bookingStatusColor(1), AppColors.confirmed);
      expect(AppHelpers.bookingStatusColor(2), AppColors.cancelled);
      expect(AppHelpers.bookingStatusColor(3), AppColors.completed);
    });

    test('defaults to primary for null/unknown', () {
      expect(AppHelpers.bookingStatusColor(null), AppColors.primary);
      expect(AppHelpers.bookingStatusColor(99), AppColors.primary);
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

  group('AppHelpers.formatIntOrDash', () {
    test('returns "-" when value is 0', () {
      expect(AppHelpers.formatIntOrDash(0), '-');
    });

    test('returns the number as string for positive values', () {
      expect(AppHelpers.formatIntOrDash(100), '100');
      expect(AppHelpers.formatIntOrDash(1), '1');
      expect(AppHelpers.formatIntOrDash(9999), '9999');
    });

    test('returns the number as string for negative values', () {
      expect(AppHelpers.formatIntOrDash(-5), '-5');
    });
  });

  group('AppHelpers.formatPriceOrDash', () {
    test('returns "-" when price is 0', () {
      expect(AppHelpers.formatPriceOrDash(0), '-');
    });

    test('delegates to formatPrice for non-zero millions', () {
      expect(AppHelpers.formatPriceOrDash(1500000), '1.5tr');
    });

    test('delegates to formatPrice for non-zero thousands', () {
      expect(AppHelpers.formatPriceOrDash(500000), '500k');
    });

    test('delegates to formatPrice for exact million', () {
      expect(AppHelpers.formatPriceOrDash(1000000), '1.0tr');
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
