import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/data/models/booking_model.dart';
import 'package:mobile/features/bookings/utils/guest_flow_filter.dart';

BookingModel _booking({
  required String id,
  required DateTime checkIn,
  required DateTime checkOut,
  BookingStatus status = BookingStatus.confirmed,
}) {
  return BookingModel(
    id: id,
    propertyId: 'p1',
    checkinDate: checkIn,
    checkoutDate: checkOut,
    status: status,
    property: const {'name': 'Căn A'},
  );
}

void main() {
  final today = GuestFlowFilter.dateOnly(DateTime.now());

  group('GuestFlowFilter.checkIn', () {
    test('includes hold/confirmed with check-in today or future', () {
      final bookings = [
        _booking(
          id: '1',
          checkIn: today,
          checkOut: today.add(const Duration(days: 2)),
          status: BookingStatus.hold,
        ),
        _booking(
          id: '2',
          checkIn: today.add(const Duration(days: 3)),
          checkOut: today.add(const Duration(days: 5)),
        ),
        _booking(
          id: '3',
          checkIn: today.subtract(const Duration(days: 1)),
          checkOut: today.add(const Duration(days: 1)),
          status: BookingStatus.confirmed,
        ),
        _booking(
          id: '4',
          checkIn: today.add(const Duration(days: 20)),
          checkOut: today.add(const Duration(days: 22)),
        ),
      ];

      final result = GuestFlowFilter.filter(bookings, GuestFlowType.checkIn);

      expect(result.map((b) => b.id), ['1', '2']);
    });
  });

  group('GuestFlowFilter.checkOut', () {
    test('includes confirmed/completed checkout within window', () {
      final bookings = [
        _booking(
          id: '1',
          checkIn: today.subtract(const Duration(days: 2)),
          checkOut: today,
        ),
        _booking(
          id: '2',
          checkIn: today.subtract(const Duration(days: 1)),
          checkOut: today.add(const Duration(days: 2)),
          status: BookingStatus.completed,
        ),
        _booking(
          id: '3',
          checkIn: today.add(const Duration(days: 1)),
          checkOut: today.add(const Duration(days: 3)),
          status: BookingStatus.hold,
        ),
      ];

      final result = GuestFlowFilter.filter(bookings, GuestFlowType.checkOut);

      expect(result.map((b) => b.id), ['1', '2']);
    });
  });
}
