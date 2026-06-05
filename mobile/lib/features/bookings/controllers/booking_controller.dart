import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../utils/guest_flow_filter.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../reports/controllers/report_controller.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(),
);

// ─── Calendar params helper ───────────────────────────────────────────────────
class CalendarParams {
  final String propertyId;
  final int year;
  final int month;

  const CalendarParams({
    required this.propertyId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      other is CalendarParams &&
      other.propertyId == propertyId &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode => Object.hash(propertyId, year, month);
}

// ─── Detail provider ─────────────────────────────────────────────────────────
final bookingDetailProvider =
    FutureProvider.family<BookingModel, String>((ref, id) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final result = await repo.getBookingDetail(id);
  if (result.success)
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  throw Exception(result.message);
});

// ─── Check-in / check-out sắp tới (lọc từ danh sách booking) ─────────────────
final guestFlowBookingsProvider = FutureProvider.autoDispose
    .family<List<BookingModel>, GuestFlowType>((ref, type) async {
  final bookings = await ref.watch(bookingListProvider(null).future);
  return GuestFlowFilter.filter(bookings, type);
});

// ─── List provider (optional propertyId filter) ───────────────────────────────
final bookingListProvider = FutureProvider.autoDispose
    .family<List<BookingModel>, String?>((ref, propertyId) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 2), link.close);
  ref.onDispose(timer.cancel);
  final repo = ref.watch(bookingRepositoryProvider);
  final result = await repo.getBookings(propertyId: propertyId);
  if (result.success)
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  throw Exception(result.message);
});

// ─── Calendar provider ────────────────────────────────────────────────────────
final calendarProvider =
    FutureProvider.family<List<CalendarBooking>, CalendarParams>(
        (ref, params) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final result =
      await repo.getCalendar(params.propertyId, params.year, params.month);
  if (result.success)
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  throw Exception(result.message);
});

// ─── Actions notifier ─────────────────────────────────────────────────────────
class BookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingRepository _repo;
  final Ref _ref;

  BookingActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  void _refreshAll() {
    _ref.invalidate(bookingListProvider);
    _ref.invalidate(calendarProvider);
    _ref.invalidate(calendarGridProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(reportDataProvider);
  }

  Future<bool> hold(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.holdRoom(data);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> confirm(String id, {String? propertyId}) async {
    state = const AsyncValue.loading();
    final result = await _repo.confirmBooking(id);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> cancel(String id, {String? propertyId}) async {
    state = const AsyncValue.loading();
    final result = await _repo.cancelBooking(id);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateBooking(id, data);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final bookingActionsProvider =
    StateNotifierProvider<BookingActionsNotifier, AsyncValue<void>>((ref) {
  return BookingActionsNotifier(
    ref.read(bookingRepositoryProvider),
    ref,
  );
});
