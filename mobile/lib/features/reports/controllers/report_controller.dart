import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/room_model.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../rooms/controllers/room_controller.dart';

/// Report data model — thống kê tổng hợp
class ReportData {
  final int totalRooms;
  final int activeRooms;
  final int totalBookings;
  final int thisMonthBookings;
  final int holdCount;
  final int confirmedCount;
  final int cancelledCount;
  final int completedCount;
  final double totalDeposit;
  final double occupancyRate;
  final int roomsWithCover;
  final int roomsWithPrice;
  final List<BookingModel> recentBookings;

  const ReportData({
    this.totalRooms = 0,
    this.activeRooms = 0,
    this.totalBookings = 0,
    this.thisMonthBookings = 0,
    this.holdCount = 0,
    this.confirmedCount = 0,
    this.cancelledCount = 0,
    this.completedCount = 0,
    this.totalDeposit = 0,
    this.occupancyRate = 0,
    this.roomsWithCover = 0,
    this.roomsWithPrice = 0,
    this.recentBookings = const [],
  });
}

/// Provider tính toán report từ rooms + bookings
final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final rooms = await ref.watch(roomListProvider(null).future);
  final bookings = await ref.watch(bookingListProvider(null).future);
  return _computeReport(rooms, bookings);
});

ReportData _computeReport(
    List<RoomModel> rooms, List<BookingModel> bookings) {
  final now = DateTime.now();

  final totalRooms = rooms.length;
  final activeRooms = rooms.where((r) => r.isActive).length;

  final holdCount =
      bookings.where((b) => b.status == BookingStatus.hold).length;
  final confirmedCount =
      bookings.where((b) => b.status == BookingStatus.confirmed).length;
  final cancelledCount =
      bookings.where((b) => b.status == BookingStatus.cancelled).length;
  final completedCount =
      bookings.where((b) => b.status == BookingStatus.completed).length;

  final totalDeposit = bookings
      .where((b) =>
          b.status == BookingStatus.confirmed ||
          b.status == BookingStatus.completed)
      .fold<double>(0, (sum, b) => sum + (b.depositAmount ?? 0));

  final thisMonthBookings = bookings
      .where(
          (b) => b.checkinDate.month == now.month && b.checkinDate.year == now.year)
      .length;

  final occupancyRate = totalRooms > 0
      ? ((confirmedCount + completedCount) / totalRooms * 100).clamp(0, 100).toDouble()
      : 0.0;

  final roomsWithCover =
      rooms.where((r) => r.coverImageUrl != null).length;
  final roomsWithPrice = rooms.where((r) => r.price != null).length;

  final recentBookings = bookings.take(5).toList();

  return ReportData(
    totalRooms: totalRooms,
    activeRooms: activeRooms,
    totalBookings: bookings.length,
    thisMonthBookings: thisMonthBookings,
    holdCount: holdCount,
    confirmedCount: confirmedCount,
    cancelledCount: cancelledCount,
    completedCount: completedCount,
    totalDeposit: totalDeposit,
    occupancyRate: occupancyRate,
    roomsWithCover: roomsWithCover,
    roomsWithPrice: roomsWithPrice,
    recentBookings: recentBookings,
  );
}
