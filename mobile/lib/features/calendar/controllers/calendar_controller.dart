import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/calendar_model.dart';
import '../../../data/repositories/calendar_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final calendarRepositoryProvider =
    Provider<CalendarRepository>((ref) => CalendarRepository());

// ─── Property groups provider ─────────────────────────────────────────────────
class PropertyGroupFilter {
  final String? category;
  final String? ownerId;

  const PropertyGroupFilter({this.category, this.ownerId});

  @override
  bool operator ==(Object other) =>
      other is PropertyGroupFilter &&
      category == other.category &&
      ownerId == other.ownerId;

  @override
  int get hashCode => Object.hash(category, ownerId);
}

final calendarPropertyGroupsProvider = FutureProvider.family<
    List<CalendarPropertyGroup>, PropertyGroupFilter?>(
  (ref, filter) async {
    final repo = ref.read(calendarRepositoryProvider);
    final result = await repo.getPropertyGroups(
      category: filter?.category,
      ownerId: filter?.ownerId,
    );
    if (result.success) return result.data!;
    throw Exception(result.message);
  },
);

// ─── Grid provider ────────────────────────────────────────────────────────────
class CalendarGridParams {
  final String propertyGroupId;
  final String startDate;
  final String endDate;

  const CalendarGridParams({
    required this.propertyGroupId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      other is CalendarGridParams &&
      propertyGroupId == other.propertyGroupId &&
      startDate == other.startDate &&
      endDate == other.endDate;

  @override
  int get hashCode => Object.hash(propertyGroupId, startDate, endDate);
}

final calendarGridProvider =
    FutureProvider.family<CalendarGrid, CalendarGridParams>(
  (ref, params) async {
    final repo = ref.read(calendarRepositoryProvider);
    final result = await repo.getGrid(
      propertyGroupId: params.propertyGroupId,
      startDate: params.startDate,
      endDate: params.endDate,
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
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.lockRoom(propertyId: propertyId, date: date);
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
