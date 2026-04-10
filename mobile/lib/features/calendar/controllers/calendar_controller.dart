import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/calendar_model.dart';
import '../../../data/repositories/calendar_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final calendarRepositoryProvider =
    Provider<CalendarRepository>((ref) => CalendarRepository());

// ─── Grid params ──────────────────────────────────────────────────────────────
class CalendarGridParams {
  final String startDate;
  final String endDate;
  final String? propertyId;
  final int? type; // 0=VILLA, 1=HOMESTAY, 2=HOTEL
  final bool isPublic; // true = /public-grid, false = /grid

  const CalendarGridParams({
    required this.startDate,
    required this.endDate,
    this.propertyId,
    this.type,
    this.isPublic = false,
  });

  @override
  bool operator ==(Object other) =>
      other is CalendarGridParams &&
      startDate == other.startDate &&
      endDate == other.endDate &&
      propertyId == other.propertyId &&
      type == other.type &&
      isPublic == other.isPublic;

  @override
  int get hashCode =>
      Object.hash(startDate, endDate, propertyId, type, isPublic);
}

// ─── Grid provider ────────────────────────────────────────────────────────────
final calendarGridProvider =
    FutureProvider.family<CalendarGrid, CalendarGridParams>(
  (ref, params) async {
    final repo = ref.read(calendarRepositoryProvider);
    final result = params.isPublic
        ? await repo.getPublicGrid(
            startDate: params.startDate,
            endDate: params.endDate,
            propertyId: params.propertyId,
            type: params.type,
          )
        : await repo.getGrid(
            startDate: params.startDate,
            endDate: params.endDate,
            propertyId: params.propertyId,
            type: params.type,
          );
    if (result.success) return result.data!;
    throw Exception(result.message);
  },
);

// ─── Admin contact provider ───────────────────────────────────────────────────
final adminContactProvider = FutureProvider<AdminContact>((ref) async {
  final repo = ref.read(calendarRepositoryProvider);
  final result = await repo.getAdminContact();
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── Lock/Unlock actions ──────────────────────────────────────────────────────
class CalendarActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final CalendarRepository _repo;
  final Ref _ref;

  CalendarActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> lockRoom({
    required String propertyId,
    required String date,
    required CalendarGridParams gridParams,
    int status = 0,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.lockRoom(
      propertyId: propertyId,
      date: date,
      status: status,
    );
    if (result.success) {
      _ref.invalidate(calendarGridProvider(gridParams));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> unlockRoom({
    required String propertyId,
    required String date,
    required CalendarGridParams gridParams,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.unlockRoom(propertyId: propertyId, date: date);
    if (result.success) {
      _ref.invalidate(calendarGridProvider(gridParams));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> markAsSold({
    required String propertyId,
    required String date,
    required CalendarGridParams gridParams,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.markAsSold(propertyId: propertyId, date: date);
    if (result.success) {
      _ref.invalidate(calendarGridProvider(gridParams));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final calendarActionsProvider =
    StateNotifierProvider<CalendarActionsNotifier, AsyncValue<void>>((ref) {
  return CalendarActionsNotifier(
    ref.read(calendarRepositoryProvider),
    ref,
  );
});
