import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/data/models/booking_model.dart';

void main() {
  group('BookingModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'b-1',
        'propertyId': 'p-1',
        'saleId': 's-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-03T00:00:00.000Z',
        'status': 0, // HOLD
        'holdExpireAt': '2026-04-02T10:00:00.000Z',
        'customerName': 'Khách Test',
        'customerPhone': '0912345678',
        'depositAmount': 500000,
        'notes': 'Ghi chú',
        'holdRemainingSeconds': 3600,
        'property': {'name': 'Villa Hạ Long'},
        'sale': {'name': 'Staff A'},
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 'b-1');
      expect(booking.propertyId, 'p-1');
      expect(booking.status, BookingStatus.hold);
      expect(booking.customerName, 'Khách Test');
      expect(booking.depositAmount, 500000.0);
      expect(booking.holdRemainingSeconds, 3600);
      expect(booking.propertyName, 'Villa Hạ Long');
      expect(booking.saleName, 'Staff A');
    });

    test('nights calculated correctly', () {
      final booking = BookingModel.fromJson({
        'id': 'b-1',
        'propertyId': 'p-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-05T00:00:00.000Z',
        'status': 1, // CONFIRMED
      });

      expect(booking.nights, 4);
    });

    test('defaults for missing optional fields', () {
      final booking = BookingModel.fromJson({
        'id': 'b-1',
        'propertyId': 'p-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-02T00:00:00.000Z',
        'status': 0, // HOLD
      });

      expect(booking.customerName, isNull);
      expect(booking.customerPhone, isNull);
      expect(booking.depositAmount, isNull);
      expect(booking.notes, isNull);
      expect(booking.holdRemainingSeconds, 0);
      expect(booking.propertyName, 'N/A');
      expect(booking.saleName, 'N/A');
      // Money/checkin fields (v1.31) default null.
      expect(booking.remainingAmount, isNull);
      expect(booking.priceBreakdown, isNull);
      expect(booking.depositProofUrl, isNull);
      expect(booking.checkedInAt, isNull);
      expect(booking.completedAt, isNull);
    });

    test('parses money + checkin fields and priceBreakdown (v1.31)', () {
      final booking = BookingModel.fromJson({
        'id': 'b-1',
        'propertyId': 'p-1',
        'checkinDate': '2026-06-15T00:00:00.000Z',
        'checkoutDate': '2026-06-17T00:00:00.000Z',
        'status': 1, // CONFIRMED
        'totalAmount': 4000000,
        'paidAmount': 0,
        'remainingAmount': 4000000,
        'depositProofUrl': 'https://res.cloudinary.com/x/bill.jpg',
        'checkedInAt': null,
        'priceBreakdown': {
          'nights': 2,
          'lineItems': [
            {'date': '2026-06-15', 'type': 'weekday', 'amount': 2000000},
            {'date': '2026-06-16', 'type': 'weekend', 'amount': 2000000},
          ],
          'extraAdults': 1,
          'surchargeTotal': 0,
          'roomTotal': 4000000,
          'total': 4000000,
        },
      });

      expect(booking.totalAmount, 4000000.0);
      expect(booking.paidAmount, 0.0);
      expect(booking.remainingAmount, 4000000.0);
      expect(booking.depositProofUrl, 'https://res.cloudinary.com/x/bill.jpg');
      expect(booking.hasPrice, true);
      // CONFIRMED + checkedInAt null → có thể check-in.
      expect(booking.canCheckin, true);

      final bd = booking.priceBreakdown!;
      expect(bd.nights, 2);
      expect(bd.lineItems.length, 2);
      expect(bd.lineItems.first.type, 'weekday');
      expect(bd.lineItems.first.amount, 2000000.0);
      expect(bd.extraAdults, 1);
      expect(bd.total, 4000000.0);
    });

    test('hasPrice false + canCheckin false when appropriate', () {
      // Chưa cấu hình giá → totalAmount null.
      final noPrice = BookingModel.fromJson({
        'id': 'b-2',
        'propertyId': 'p-1',
        'checkinDate': '2026-06-15T00:00:00.000Z',
        'checkoutDate': '2026-06-17T00:00:00.000Z',
        'status': 1,
      });
      expect(noPrice.hasPrice, false);

      // Đã check-in → không cho check-in lại.
      final checkedIn = BookingModel.fromJson({
        'id': 'b-3',
        'propertyId': 'p-1',
        'checkinDate': '2026-06-15T00:00:00.000Z',
        'checkoutDate': '2026-06-17T00:00:00.000Z',
        'status': 1,
        'checkedInAt': '2026-06-15T08:00:00.000Z',
      });
      expect(checkedIn.canCheckin, false);

      // HOLD → chưa tới bước check-in.
      final hold = BookingModel.fromJson({
        'id': 'b-4',
        'propertyId': 'p-1',
        'checkinDate': '2026-06-15T00:00:00.000Z',
        'checkoutDate': '2026-06-17T00:00:00.000Z',
        'status': 0,
      });
      expect(hold.canCheckin, false);
    });
  });

  group('CalendarBooking', () {
    test('coversDate works correctly', () {
      final cb = CalendarBooking.fromJson({
        'id': 'cb-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-04T00:00:00.000Z',
        'status': 1, // CONFIRMED
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
