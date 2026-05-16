import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/room_repository.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../reports/controllers/report_controller.dart';

final roomRepositoryProvider =
    Provider<RoomRepository>((ref) => RoomRepository());

// Provider lấy danh sách phòng (scoped theo owner — dùng cho quản lý)
final roomListProvider =
    FutureProvider.family<List<RoomModel>, String?>((ref, homestayId) async {
  final repo = ref.read(roomRepositoryProvider);
  final result = await repo.getRooms(homestayId: homestayId);
  if (result.success) return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  throw Exception(result.message);
});

// Provider lấy TẤT CẢ phòng active (dùng cho danh sách phòng — mọi role)
final allRoomsProvider =
    FutureProvider.autoDispose<List<RoomModel>>((ref) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 2), link.close);
  final repo = ref.read(roomRepositoryProvider);
  final result = await repo.getAllPublicRooms();
  if (result.success) return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  throw Exception(result.message);
});

// Provider lấy chi tiết phòng
final roomDetailProvider =
    FutureProvider.family<RoomModel, String>((ref, id) async {
  final repo = ref.read(roomRepositoryProvider);
  final result = await repo.getRoomDetail(id);
  if (result.success) return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  throw Exception(result.message);
});

// Actions notifier cho mutations (create, update, delete, upload images, upsert price)
final roomActionsProvider =
    StateNotifierProvider<RoomActionsNotifier, AsyncValue<void>>((ref) {
  return RoomActionsNotifier(ref.read(roomRepositoryProvider), ref);
});

class RoomActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final RoomRepository _repo;
  final Ref _ref;

  RoomActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  void _refreshAll({String? id}) {
    _ref.invalidate(roomListProvider);
    _ref.invalidate(allRoomsProvider);
    if (id != null) _ref.invalidate(roomDetailProvider(id));
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(reportDataProvider);
  }

  Future<RoomModel?> create(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.createRoom(data);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return result.data;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return null;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateRoom(id, data);
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
    final result = await _repo.deleteRoom(id);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<(bool, String)> uploadImages(
      String roomId, List<String> filePaths) async {
    final result = await _repo.uploadImages(roomId, filePaths);
    if (result.success) {
      _ref.invalidate(roomDetailProvider(roomId));
      _ref.invalidate(allRoomsProvider);
      return (true, '');
    }
    return (false, result.message);
  }

  Future<bool> deleteImage(String roomId, String imageId) async {
    final result = await _repo.deleteImage(roomId, imageId);
    if (result.success) {
      _ref.invalidate(roomDetailProvider(roomId));
      _ref.invalidate(allRoomsProvider);
      return true;
    }
    return false;
  }

  Future<bool> setCoverImage(String roomId, String imageId) async {
    final result = await _repo.setCoverImage(roomId, imageId);
    if (result.success) {
      _ref.invalidate(roomDetailProvider(roomId));
      _ref.invalidate(allRoomsProvider);
      return true;
    }
    return false;
  }

  Future<bool> upsertPrice(String roomId, Map<String, dynamic> data) async {
    final result = await _repo.upsertPrice(roomId, data);
    if (result.success) {
      _refreshAll(id: roomId);
      return true;
    }
    return false;
  }
}
