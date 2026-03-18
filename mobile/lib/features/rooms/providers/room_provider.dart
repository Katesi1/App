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
