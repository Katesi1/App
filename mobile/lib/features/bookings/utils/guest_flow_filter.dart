import '../../../core/constants/app_constants.dart';
import '../../../data/models/booking_model.dart';

/// Lọc booking cho luồng check-in / check-out sắp tới.
enum GuestFlowType { checkIn, checkOut }

class GuestFlowFilter {
  GuestFlowFilter._();

  static const int defaultDaysAhead = 14;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static List<BookingModel> filter(
    List<BookingModel> bookings,
    GuestFlowType type, {
    int daysAhead = defaultDaysAhead,
  }) {
    final today = dateOnly(DateTime.now());
    final end = today.add(Duration(days: daysAhead));

    final filtered = bookings.where((b) {
      return switch (type) {
        GuestFlowType.checkIn => _isUpcomingCheckIn(b, today, end),
        GuestFlowType.checkOut => _isUpcomingCheckOut(b, today, end),
      };
    }).toList();

    filtered.sort((a, b) {
      final dateA =
          type == GuestFlowType.checkIn ? a.checkinDate : a.checkoutDate;
      final dateB =
          type == GuestFlowType.checkIn ? b.checkinDate : b.checkoutDate;
      return dateA.compareTo(dateB);
    });

    return filtered;
  }

  static Map<String, List<BookingModel>> groupByProperty(
    List<BookingModel> bookings,
  ) {
    final groups = <String, List<BookingModel>>{};
    for (final booking in bookings) {
      groups.putIfAbsent(booking.propertyId, () => []).add(booking);
    }
    return groups;
  }

  static bool _isUpcomingCheckIn(
    BookingModel booking,
    DateTime today,
    DateTime end,
  ) {
    if (booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.noShow) {
      return false;
    }
    final checkIn = dateOnly(booking.checkinDate);
    return !checkIn.isBefore(today) && !checkIn.isAfter(end);
  }

  static bool _isUpcomingCheckOut(
    BookingModel booking,
    DateTime today,
    DateTime end,
  ) {
    if (booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.hold ||
        booking.status == BookingStatus.noShow) {
      return false;
    }
    final checkOut = dateOnly(booking.checkoutDate);
    return !checkOut.isBefore(today) && !checkOut.isAfter(end);
  }
}
