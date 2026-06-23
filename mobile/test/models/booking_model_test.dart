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
    });

    test('parses NO_SHOW status (4)', () {
      final booking = BookingModel.fromJson({
        'id': 'b-noshow',
        'propertyId': 'p-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-03T00:00:00.000Z',
        'status': 4,
      });

      expect(booking.status, BookingStatus.noShow);
    });

    test('parses cancellation tracking fields (BE v1.14+)', () {
      final booking = BookingModel.fromJson({
        'id': 'b-cancel',
        'propertyId': 'p-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-03T00:00:00.000Z',
        'status': 2, // CANCELLED
        'cancelledAt': '2026-06-13T10:00:00.000Z',
        'cancelledByUserId': 'u-1',
        'cancelledByRole': 1, // OWNER
        'cancelledReason': 'Khách đổi lịch',
      });

      expect(booking.cancelledAt, isNotNull);
      expect(booking.cancelledByUserId, 'u-1');
      expect(booking.cancelledByRole, 1);
      expect(booking.cancelledReason, 'Khách đổi lịch');
    });

    test('cancellation fields null cho booking cũ trước migration', () {
      final booking = BookingModel.fromJson({
        'id': 'b-old',
        'propertyId': 'p-1',
        'checkinDate': '2026-04-01T00:00:00.000Z',
        'checkoutDate': '2026-04-03T00:00:00.000Z',
        'status': 2, // CANCELLED nhưng không có tracking
      });

      expect(booking.cancelledAt, isNull);
      expect(booking.cancelledByUserId, isNull);
      expect(booking.cancelledByRole, isNull);
      expect(booking.cancelledReason, isNull);
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

  // ─────────────────────────────────────────────
  // Edge cases — BookingModel
  // ─────────────────────────────────────────────
  group('BookingModel — edge cases', () {
    test('fromJson với id null trả về chuỗi rỗng', () {
      // Arrange
      final json = {
        'id': null,
        'propertyId': 'p-1',
        'checkinDate': '2026-05-01T00:00:00.000Z',
        'checkoutDate': '2026-05-02T00:00:00.000Z',
        'status': 0,
      };

      // Act
      final booking = BookingModel.fromJson(json);

      // Assert
      expect(booking.id, '');
    });

    test('fromJson với checkinDate chuỗi rỗng không crash', () {
      // Arrange — chuỗi không hợp lệ → _parseDate fallback DateTime.now()
      final json = {
        'id': 'b-1',
        'propertyId': 'p-1',
        'checkinDate': 'not-a-date',
        'checkoutDate': '2026-05-10T00:00:00.000Z',
        'status': 0,
      };

      // Act & Assert — không được throw
      expect(() => BookingModel.fromJson(json), returnsNormally);
    });

    test('nights bằng 0 khi checkin = checkout', () {
      // Arrange
      final booking = BookingModel.fromJson({
        'id': 'b-2',
        'propertyId': 'p-1',
        'checkinDate': '2026-05-01T00:00:00.000Z',
        'checkoutDate': '2026-05-01T00:00:00.000Z',
        'status': 1,
      });

      // Act & Assert
      expect(booking.nights, 0);
    });

    test('nights âm khi checkout trước checkin', () {
      // Arrange — backend không nên gửi dữ liệu này, nhưng model không crash
      final booking = BookingModel.fromJson({
        'id': 'b-3',
        'propertyId': 'p-1',
        'checkinDate': '2026-05-05T00:00:00.000Z',
        'checkoutDate': '2026-05-01T00:00:00.000Z',
        'status': 1,
      });

      // Act & Assert — difference().inDays trả số âm
      expect(booking.nights, isNegative);
    });

    test('saleName fallback "N/A" khi sale null', () {
      // Arrange
      final booking = BookingModel.fromJson({
        'id': 'b-4',
        'propertyId': 'p-1',
        'checkinDate': '2026-05-01T00:00:00.000Z',
        'checkoutDate': '2026-05-02T00:00:00.000Z',
        'status': 1,
        'sale': null,
      });

      // Act & Assert
      expect(booking.saleName, 'N/A');
    });

    test('saleName fallback "N/A" khi key "sale" không có trong json', () {
      // Arrange
      final booking = BookingModel.fromJson({
        'id': 'b-5',
        'propertyId': 'p-1',
        'checkinDate': '2026-05-01T00:00:00.000Z',
        'checkoutDate': '2026-05-02T00:00:00.000Z',
        'status': 1,
      });

      // Act & Assert
      expect(booking.saleName, 'N/A');
    });
  });

  // ─────────────────────────────────────────────
  // Edge cases — CalendarBooking
  // ─────────────────────────────────────────────
  group('CalendarBooking — edge cases', () {
    CalendarBooking makeBooking({
      String checkin = '2026-06-10T00:00:00.000Z',
      String checkout = '2026-06-15T00:00:00.000Z',
    }) {
      return CalendarBooking.fromJson({
        'id': 'cb-edge',
        'checkinDate': checkin,
        'checkoutDate': checkout,
        'status': 1,
      });
    }

    test('coversDate — ngày đúng bằng checkin trả về true', () {
      // Arrange
      final cb = makeBooking();

      // Act & Assert
      expect(cb.coversDate(DateTime(2026, 6, 10)), true);
    });

    test('coversDate — ngày đúng bằng checkout trả về false (exclusive)', () {
      // Arrange
      final cb = makeBooking();

      // Act & Assert
      expect(cb.coversDate(DateTime(2026, 6, 15)), false);
    });

    test('coversDate — ngày trước checkin trả về false', () {
      // Arrange
      final cb = makeBooking();

      // Act & Assert
      expect(cb.coversDate(DateTime(2026, 6, 9)), false);
    });

    test('coversDate bỏ qua time component — chỉ so sánh theo ngày', () {
      // Arrange
      final cb = makeBooking();

      // Act — truyền DateTime có giờ khác nhau trong cùng ngày
      final dateWithTime = DateTime(2026, 6, 10, 23, 59, 59);

      // Assert
      expect(cb.coversDate(dateWithTime), true);
    });

    test('saleName của CalendarBooking trả về chuỗi rỗng khi sale null', () {
      // Arrange
      final cb = CalendarBooking.fromJson({
        'id': 'cb-nosale',
        'checkinDate': '2026-06-10T00:00:00.000Z',
        'checkoutDate': '2026-06-12T00:00:00.000Z',
        'status': 0,
        'sale': null,
      });

      // Act & Assert — CalendarBooking.saleName dùng '' (không phải 'N/A')
      expect(cb.saleName, '');
    });

    test('fromJson với checkinDate null không crash', () {
      // Arrange — _parseDate(null) → DateTime.now()
      final json = {
        'id': 'cb-nulldate',
        'checkinDate': null,
        'checkoutDate': '2026-06-15T00:00:00.000Z',
        'status': 1,
      };

      // Act & Assert
      expect(() => CalendarBooking.fromJson(json), returnsNormally);
    });
  });
}
