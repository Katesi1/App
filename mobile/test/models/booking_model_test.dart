import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/data/models/booking_model.dart';

void main() {
  group('BookingModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'b-1',
        'roomId': 'r-1',
        'saleId': 's-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-03T00:00:00.000Z',
        'status': 'HOLD',
        'holdExpireAt': '2026-04-02T10:00:00.000Z',
        'customerName': 'Khách Test',
        'customerPhone': '0912345678',
        'depositAmount': 500000,
        'notes': 'Ghi chú',
        'holdRemainingSeconds': 3600,
        'room': {'name': 'P.101', 'homestay': {'name': 'HL Resort'}},
        'sale': {'name': 'Staff A'},
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 'b-1');
      expect(booking.roomId, 'r-1');
      expect(booking.status, BookingStatus.hold);
      expect(booking.customerName, 'Khách Test');
      expect(booking.depositAmount, 500000.0);
      expect(booking.holdRemainingSeconds, 3600);
      expect(booking.roomName, 'P.101');
      expect(booking.homestayName, 'HL Resort');
      expect(booking.saleName, 'Staff A');
    });

    test('nights calculated correctly', () {
      final booking = BookingModel.fromJson({
        'id': 'b-1',
        'roomId': 'r-1',
        'saleId': 's-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-05T00:00:00.000Z',
        'status': 'CONFIRMED',
      });

      expect(booking.nights, 4);
    });

    test('defaults for missing optional fields', () {
      final booking = BookingModel.fromJson({
        'id': 'b-1',
        'roomId': 'r-1',
        'saleId': 's-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-02T00:00:00.000Z',
        'status': 'HOLD',
      });

      expect(booking.customerName, isNull);
      expect(booking.customerPhone, isNull);
      expect(booking.depositAmount, 0.0);
      expect(booking.notes, isNull);
      expect(booking.holdRemainingSeconds, 0);
      expect(booking.roomName, 'N/A');
      expect(booking.homestayName, 'N/A');
      expect(booking.saleName, 'N/A');
    });
  });

  group('CalendarBooking', () {
    test('coversDate works correctly', () {
      final cb = CalendarBooking.fromJson({
        'id': 'cb-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-04T00:00:00.000Z',
        'status': 'CONFIRMED',
      });

      // Ngày trong khoảng → true
      expect(cb.coversDate(DateTime(2026, 4, 1)), true);
      expect(cb.coversDate(DateTime(2026, 4, 2)), true);
      expect(cb.coversDate(DateTime(2026, 4, 3)), true);

      // Ngày checkout (4/4) → false (checkout day không tính)
      expect(cb.coversDate(DateTime(2026, 4, 4)), false);

      // Ngày trước checkin → false
      expect(cb.coversDate(DateTime(2026, 3, 31)), false);

      // Ngày sau checkout → false
      expect(cb.coversDate(DateTime(2026, 4, 5)), false);
    });
  });
}
