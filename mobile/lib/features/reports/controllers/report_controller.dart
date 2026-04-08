import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/report_repository.dart';

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

  factory ReportData.fromJson(Map<String, dynamic> json) => ReportData(
        totalRooms: json['totalRooms'] ?? 0,
        activeRooms: json['activeRooms'] ?? 0,
        totalBookings: json['totalBookings'] ?? 0,
        thisMonthBookings: json['thisMonthBookings'] ?? 0,
        holdCount: json['holdCount'] ?? 0,
        confirmedCount: json['confirmedCount'] ?? 0,
        cancelledCount: json['cancelledCount'] ?? 0,
        completedCount: json['completedCount'] ?? 0,
        totalDeposit: (json['totalDeposit'] as num?)?.toDouble() ?? 0,
        occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0,
        roomsWithCover: json['roomsWithCover'] ?? 0,
        roomsWithPrice: json['roomsWithPrice'] ?? 0,
        recentBookings:
            (json['recentBookingsParsed'] as List<BookingModel>?) ?? [],
      );
}

/// Filter params cho report
class ReportParams {
  final int? month;
  final int? year;

  const ReportParams({this.month, this.year});

  @override
  bool operator ==(Object other) =>
      other is ReportParams && month == other.month && year == other.year;

  @override
  int get hashCode => Object.hash(month, year);
}

final reportRepositoryProvider =
    Provider<ReportRepository>((ref) => ReportRepository());

/// Provider lấy report từ real API /reports
final reportDataProvider =
    FutureProvider.family<ReportData, ReportParams?>((ref, params) async {
  final repo = ref.read(reportRepositoryProvider);
  final result = await repo.getReport(
    month: params?.month,
    year: params?.year,
  );
  if (result.success) return ReportData.fromJson(result.data!);
  throw Exception(result.message);
});
