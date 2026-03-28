import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/room_model.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../rooms/controllers/room_controller.dart';

/// Dashboard KPI data model
class DashboardStats {
  final int totalRooms;
  final int activeRooms;
  final int emptyRooms;
  final int occupiedRooms;
  final int checkoutToday;
  final int totalBookings;
  final int thisMonthBookings;
  final double monthlyRevenue;
  final double todayRevenue;

  const DashboardStats({
    this.totalRooms = 0,
    this.activeRooms = 0,
    this.emptyRooms = 0,
    this.occupiedRooms = 0,
    this.checkoutToday = 0,
    this.totalBookings = 0,
    this.thisMonthBookings = 0,
    this.monthlyRevenue = 0,
    this.todayRevenue = 0,
  });
}

/// Provider tính toán KPI dashboard từ rooms + bookings
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final rooms = await ref.watch(roomListProvider(null).future);
  final bookings = await ref.watch(bookingListProvider(null).future);
  return _computeStats(rooms, bookings);
});

DashboardStats _computeStats(
    List<RoomModel> rooms, List<BookingModel> bookings) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final totalRooms = rooms.length;
  final activeRooms = rooms.where((r) => r.isActive).length;

  // Booking hôm nay checkout
  final checkoutToday = bookings
      .where((b) =>
          b.checkoutDate.year == today.year &&
          b.checkoutDate.month == today.month &&
          b.checkoutDate.day == today.day)
      .length;

  // Booking đang ở (confirmed + checkin <= today <= checkout)
  final occupiedRooms = bookings
      .where((b) =>
          b.status == BookingStatus.confirmed &&
          !b.checkinDate.isAfter(today) &&
          b.checkoutDate.isAfter(today))
      .length;

  final emptyRooms = (activeRooms - occupiedRooms).clamp(0, activeRooms);

  // Booking tháng này
  final thisMonthBookings = bookings
      .where(
          (b) => b.checkinDate.month == now.month && b.checkinDate.year == now.year)
      .length;

  // Doanh thu (deposit từ confirmed + completed)
  final monthlyRevenue = bookings
      .where((b) =>
          (b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.completed) &&
          b.checkinDate.month == now.month &&
          b.checkinDate.year == now.year)
      .fold<double>(0, (sum, b) => sum + (b.depositAmount ?? 0));

  final todayRevenue = bookings
      .where((b) =>
          (b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.completed) &&
          b.checkinDate.year == today.year &&
          b.checkinDate.month == today.month &&
          b.checkinDate.day == today.day)
      .fold<double>(0, (sum, b) => sum + (b.depositAmount ?? 0));

  return DashboardStats(
    totalRooms: totalRooms,
    activeRooms: activeRooms,
    emptyRooms: emptyRooms,
    occupiedRooms: occupiedRooms,
    checkoutToday: checkoutToday,
    totalBookings: bookings.length,
    thisMonthBookings: thisMonthBookings,
    monthlyRevenue: monthlyRevenue,
    todayRevenue: todayRevenue,
  );
}
