import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/homestay_model.dart';
import '../../../data/repositories/homestay_repository.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../reports/controllers/report_controller.dart';
import '../../rooms/controllers/room_controller.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final homestayRepositoryProvider = Provider<HomestayRepository>(
  (ref) => HomestayRepository(),
);

// ─── List provider ────────────────────────────────────────────────────────────
// includeInactive: true → dùng ở management screen (admin/staff thấy cả cơ sở bị tắt)
// includeInactive: false (default) → dùng ở customer / public views
final homestayListProvider =
    FutureProvider.family<List<HomestayModel>, bool>((ref, includeInactive) async {
  final repo = ref.read(homestayRepositoryProvider);
  final result = await repo.getHomestays(includeInactive: includeInactive);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── Detail provider ──────────────────────────────────────────────────────────
final homestayDetailProvider =
    FutureProvider.family<HomestayModel, String>((ref, id) async {
  final repo = ref.read(homestayRepositoryProvider);
  final result = await repo.getHomestay(id);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── Actions notifier ─────────────────────────────────────────────────────────
class HomestayActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final HomestayRepository _repo;
  final Ref _ref;

  HomestayActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  /// Invalidate tất cả providers liên quan sau mỗi action
  void _refreshAll({String? id}) {
    _ref.invalidate(homestayListProvider(true));
    _ref.invalidate(homestayListProvider(false));
    if (id != null) _ref.invalidate(homestayDetailProvider(id));
    _ref.invalidate(roomListProvider);
    _ref.invalidate(allRoomsProvider);
    _ref.invalidate(calendarGridProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(reportDataProvider);
    _ref.invalidate(bookingListProvider);
  }

  /// Trả về ID phòng vừa tạo, hoặc null nếu lỗi
  Future<String?> create(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.createHomestay(data);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return result.data!.id;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return null;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateHomestay(id, data);
    if (result.success) {
      _refreshAll(id: id);
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> toggleActive(String id, bool isActive) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateHomestay(id, {'isActive': isActive});
    if (result.success) {
      _refreshAll(id: id);
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.deleteHomestay(id);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final homestayActionsProvider =
    StateNotifierProvider<HomestayActionsNotifier, AsyncValue<void>>((ref) {
  return HomestayActionsNotifier(
    ref.read(homestayRepositoryProvider),
    ref,
  );
});
