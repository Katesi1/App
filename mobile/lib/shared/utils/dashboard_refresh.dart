import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/bookings/controllers/booking_controller.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';
import '../../features/reports/controllers/report_controller.dart';

/// Refresh stats + profile để dashboard bắt KYC/subscription mới từ backend.
Future<void> refreshDashboardData(WidgetRef ref) async {
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(bookingListProvider(null));
  // Sparkline doanh thu trên dashboard dùng chung reportDataProvider.
  ref.invalidate(reportDataProvider(const ReportParams()));
  await ref.read(authProvider.notifier).refreshProfile();
}
