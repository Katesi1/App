import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/customer/controllers/customer_controller.dart';

void main() {
  group('PublicRoomFilter', () {
    test('default constructor has all null', () {
      const filter = PublicRoomFilter();

      expect(filter.checkinDate, isNull);
      expect(filter.checkoutDate, isNull);
      expect(filter.guests, isNull);
      expect(filter.minPrice, isNull);
      expect(filter.maxPrice, isNull);
    });

    test('stores values correctly', () {
      final filter = PublicRoomFilter(
        checkinDate: DateTime(2026, 4, 1),
        checkoutDate: DateTime(2026, 4, 3),
        guests: 2,
        minPrice: 500000,
        maxPrice: 1500000,
      );

      expect(filter.checkinDate, DateTime(2026, 4, 1));
      expect(filter.checkoutDate, DateTime(2026, 4, 3));
      expect(filter.guests, 2);
      expect(filter.minPrice, 500000);
      expect(filter.maxPrice, 1500000);
    });
  });
}
