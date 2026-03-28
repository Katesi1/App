import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/room_repository.dart';

final roomRepositoryProvider =
    Provider<RoomRepository>((ref) => RoomRepository());

// Provider lấy danh sách phòng
final roomListProvider =
    FutureProvider.family<List<RoomModel>, String?>((ref, homestayId) async {
  final repo = ref.read(roomRepositoryProvider);
  final result = await repo.getRooms(homestayId: homestayId);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// Provider lấy chi tiết phòng
final roomDetailProvider =
    FutureProvider.family<RoomModel, String>((ref, id) async {
  final repo = ref.read(roomRepositoryProvider);
  final result = await repo.getRoomDetail(id);
  if (result.success) return result.data!;
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

  Future<RoomModel?> create(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.createRoom(data);
    if (result.success) {
      _ref.invalidate(roomListProvider);
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
      _ref.invalidate(roomListProvider);
      _ref.invalidate(roomDetailProvider(id));
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
      _ref.invalidate(roomListProvider);
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> uploadImages(String roomId, List<String> filePaths) async {
    final result = await _repo.uploadImages(roomId, filePaths);
    if (result.success) {
      _ref.invalidate(roomDetailProvider(roomId));
      return true;
    }
    return false;
  }

  Future<bool> upsertPrice(
      String roomId, Map<String, dynamic> data) async {
    final result = await _repo.upsertPrice(roomId, data);
    if (result.success) {
      _ref.invalidate(roomDetailProvider(roomId));
      return true;
    }
    return false;
  }
}
