import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/booking_repository.dart';
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
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.getBookingDetail(id);
  if (result.success) {
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  }
  throw Exception(result.message);
});

// ─── List provider (optional propertyId filter) ───────────────────────────────
final bookingListProvider = FutureProvider.autoDispose
    .family<List<BookingModel>, String?>((ref, propertyId) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 2), link.close);
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.getBookings(propertyId: propertyId);
  if (result.success) {
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  }
  throw Exception(result.message);
});

// ─── Calendar provider ────────────────────────────────────────────────────────
final calendarProvider =
    FutureProvider.family<List<CalendarBooking>, CalendarParams>(
        (ref, params) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result =
      await repo.getCalendar(params.propertyId, params.year, params.month);
  if (result.success) {
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  }
  throw Exception(result.message);
});

// ─── Actions notifier ─────────────────────────────────────────────────────────
class BookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingRepository _repo;
  final Ref _ref;

  BookingActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  /// Throttle giữ phòng: 1 tài khoản chỉ giữ được 1 phòng mỗi 1 phút
  /// (mirror rate-limit của BE). Lưu theo `propertyId`, sống theo phiên đăng
  /// nhập (provider không autoDispose).
  static const _holdCooldown = Duration(minutes: 1);
  final Map<String, DateTime> _lastHoldAt = {};

  /// Thời gian còn lại của cooldown cho phòng [propertyId] (0 nếu hết).
  Duration holdCooldownLeft(String propertyId) {
    final last = _lastHoldAt[propertyId];
    if (last == null) return Duration.zero;
    final left = _holdCooldown - DateTime.now().difference(last);
    return left.isNegative ? Duration.zero : left;
  }

  void _refreshAll() {
    // Invalidate đúng instance đang được các màn watch (`null` = không filter).
    // Invalidate cả family (`bookingListProvider`) với autoDispose + keepAlive
    // chỉ đẩy provider vào loading mà không refetch → kẹt skeleton sau khi
    // confirm/cancel; instance cụ thể mới refetch dứt điểm.
    _ref.invalidate(bookingListProvider(null));
    _ref.invalidate(calendarProvider);
    _ref.invalidate(calendarGridProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(reportDataProvider);
  }

  Future<bool> hold(Map<String, dynamic> data) async {
    final propertyId = data['propertyId'] as String?;
    if (propertyId != null) {
      final left = holdCooldownLeft(propertyId);
      if (left > Duration.zero) {
        state = AsyncValue.error(
          'Bạn vừa giữ phòng này. Vui lòng thử lại sau ${left.inSeconds + 1} giây.',
          StackTrace.current,
        );
        return false;
      }
    }
    state = const AsyncValue.loading();
    final result = await _repo.holdRoom(data);
    if (result.success) {
      if (propertyId != null) _lastHoldAt[propertyId] = DateTime.now();
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

  /// Ghi nhận thanh toán của khách (cọc/đủ tiền). HOLD → BE tự chuyển CONFIRMED.
  Future<bool> markPaid(String id, {double? amount}) async {
    state = const AsyncValue.loading();
    final result = await _repo.markPaid(id, amount: amount);
    if (result.success) {
      _ref.invalidate(bookingDetailProvider(id));
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
