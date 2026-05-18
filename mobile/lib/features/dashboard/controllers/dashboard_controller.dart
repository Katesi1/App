import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/dashboard_repository.dart';

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
  final int globalTotalRooms;
  final int globalEmptyRooms;

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
    this.globalTotalRooms = 0,
    this.globalEmptyRooms = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalRooms: json['totalRooms'] ?? 0,
        activeRooms: json['activeRooms'] ?? 0,
        emptyRooms: json['emptyRooms'] ?? 0,
        occupiedRooms: json['occupiedRooms'] ?? 0,
        checkoutToday: json['checkoutToday'] ?? 0,
        totalBookings: json['totalBookings'] ?? 0,
        thisMonthBookings: json['thisMonthBookings'] ?? 0,
        monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0,
        todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0,
        globalTotalRooms: json['globalTotalRooms'] ?? json['totalRooms'] ?? 0,
        globalEmptyRooms: json['globalEmptyRooms'] ?? json['emptyRooms'] ?? 0,
      );
}

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => DashboardRepository());

/// Dismiss state for "STAFF not assigned to owner" banner.
/// Invalidated on each new login so banner shows once per session.
final unassignedBannerDismissedProvider = StateProvider<bool>((ref) => false);

/// Dismiss state for trial subscription banner. Only applies to trial
/// (positive) variant. Past-due / cancelled cannot be dismissed (user must act).
final trialBannerDismissedProvider = StateProvider<bool>((ref) => false);

/// Dashboard KPI provider — fetches from /dashboard/stats.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 2), link.close);
  final repo = ref.read(dashboardRepositoryProvider);
  final result = await repo.getStats();
  if (result.success) return DashboardStats.fromJson(result.data!);
  throw Exception(result.message);
});
