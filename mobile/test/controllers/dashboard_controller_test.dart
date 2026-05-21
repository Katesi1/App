import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/repositories/dashboard_repository.dart';
import 'package:mobile/features/dashboard/controllers/dashboard_controller.dart';

// ── Fake repository ───────────────────────────────────────────────────────────
class FakeDashboardRepository extends DashboardRepository {
  Map<String, dynamic>? fakeData;
  String? errorMessage;

  @override
  Future<ApiResponse<Map<String, dynamic>>> getStats() async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    return ApiResponse(
      success: true,
      data: fakeData ?? {},
      message: '',
    );
  }
}

void main() {
  group('DashboardStats', () {
    test('default constructor has zero values', () {
      const stats = DashboardStats();
      expect(stats.totalRooms, 0);
      expect(stats.activeRooms, 0);
      expect(stats.emptyRooms, 0);
      expect(stats.occupiedRooms, 0);
      expect(stats.checkoutToday, 0);
      expect(stats.totalBookings, 0);
      expect(stats.thisMonthBookings, 0);
      expect(stats.monthlyRevenue, 0);
      expect(stats.todayRevenue, 0);
      expect(stats.globalTotalRooms, 0);
      expect(stats.globalEmptyRooms, 0);
    });

    test('fromJson parses all fields', () {
      final stats = DashboardStats.fromJson({
        'totalRooms': 10,
        'activeRooms': 8,
        'emptyRooms': 3,
        'occupiedRooms': 5,
        'checkoutToday': 2,
        'totalBookings': 100,
        'thisMonthBookings': 20,
        'monthlyRevenue': 15000000,
        'todayRevenue': 500000,
        'globalTotalRooms': 50,
        'globalEmptyRooms': 12,
      });
      expect(stats.totalRooms, 10);
      expect(stats.activeRooms, 8);
      expect(stats.emptyRooms, 3);
      expect(stats.occupiedRooms, 5);
      expect(stats.checkoutToday, 2);
      expect(stats.totalBookings, 100);
      expect(stats.thisMonthBookings, 20);
      expect(stats.monthlyRevenue, 15000000);
      expect(stats.todayRevenue, 500000);
      expect(stats.globalTotalRooms, 50);
      expect(stats.globalEmptyRooms, 12);
    });

    test('fromJson uses defaults for missing fields', () {
      final stats = DashboardStats.fromJson({});
      expect(stats.totalRooms, 0);
      expect(stats.monthlyRevenue, 0.0);
      expect(stats.todayRevenue, 0.0);
    });

    test('fromJson globalTotalRooms falls back to totalRooms if missing', () {
      final stats = DashboardStats.fromJson({'totalRooms': 5});
      expect(stats.globalTotalRooms, 5);
    });

    test('fromJson globalEmptyRooms falls back to emptyRooms if missing', () {
      final stats = DashboardStats.fromJson({'emptyRooms': 3});
      expect(stats.globalEmptyRooms, 3);
    });

    test('fromJson parses revenue as double', () {
      final stats = DashboardStats.fromJson({
        'monthlyRevenue': 1500000,
        'todayRevenue': 250000.5,
      });
      expect(stats.monthlyRevenue, 1500000.0);
      expect(stats.todayRevenue, 250000.5);
    });
  });

  group('unassignedBannerDismissedProvider', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(unassignedBannerDismissedProvider), false);
    });

    test('can be toggled to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(unassignedBannerDismissedProvider.notifier).state = true;
      expect(container.read(unassignedBannerDismissedProvider), true);
    });
  });

  group('trialBannerDismissedProvider', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(trialBannerDismissedProvider), false);
    });

    test('can be set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(trialBannerDismissedProvider.notifier).state = true;
      expect(container.read(trialBannerDismissedProvider), true);
    });
  });

  group('dashboardStatsProvider', () {
    test('returns DashboardStats on success', () async {
      final fakeRepo = FakeDashboardRepository();
      fakeRepo.fakeData = {
        'totalRooms': 5,
        'activeRooms': 4,
        'emptyRooms': 2,
        'totalBookings': 10,
        'monthlyRevenue': 3000000,
        'todayRevenue': 100000,
      };
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(dashboardStatsProvider.future);
      expect(stats.totalRooms, 5);
      expect(stats.activeRooms, 4);
      expect(stats.monthlyRevenue, 3000000);
    });

    test('throws Exception on failure', () async {
      final fakeRepo = FakeDashboardRepository();
      fakeRepo.errorMessage = 'Lỗi kết nối';
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(dashboardStatsProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
