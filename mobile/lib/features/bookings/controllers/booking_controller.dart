import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/booking_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(),
);

// ─── Calendar params helper ───────────────────────────────────────────────────
class CalendarParams {
  final String roomId;
  final int year;
  final int month;

  const CalendarParams({
    required this.roomId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      other is CalendarParams &&
      other.roomId == roomId &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode => Object.hash(roomId, year, month);
}

// ─── Detail provider ─────────────────────────────────────────────────────────
final bookingDetailProvider =
    FutureProvider.family<BookingModel, String>((ref, id) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.getBookingDetail(id);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── List provider (optional roomId filter) ───────────────────────────────────
final bookingListProvider =
    FutureProvider.family<List<BookingModel>, String?>((ref, roomId) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result = await repo.getBookings(roomId: roomId);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── Calendar provider ────────────────────────────────────────────────────────
final calendarProvider =
    FutureProvider.family<List<CalendarBooking>, CalendarParams>(
        (ref, params) async {
  final repo = ref.read(bookingRepositoryProvider);
  final result =
      await repo.getCalendar(params.roomId, params.year, params.month);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── Actions notifier ─────────────────────────────────────────────────────────
class BookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final BookingRepository _repo;
  final Ref _ref;

  BookingActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> hold(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.holdRoom(data);
    if (result.success) {
      _ref.invalidate(bookingListProvider(null));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> confirm(String id, {String? roomId}) async {
    state = const AsyncValue.loading();
    final result = await _repo.confirmBooking(id);
    if (result.success) {
      _ref.invalidate(bookingListProvider(null));
      if (roomId != null) _ref.invalidate(bookingListProvider(roomId));
      _ref.invalidate(calendarProvider);
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> cancel(String id, {String? roomId}) async {
    state = const AsyncValue.loading();
    final result = await _repo.cancelBooking(id);
    if (result.success) {
      _ref.invalidate(bookingListProvider(null));
      if (roomId != null) _ref.invalidate(bookingListProvider(roomId));
      _ref.invalidate(calendarProvider);
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
      _ref.invalidate(bookingListProvider(null));
      _ref.invalidate(calendarProvider);
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
