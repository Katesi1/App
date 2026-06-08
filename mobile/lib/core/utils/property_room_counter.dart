import '../../data/models/homestay_model.dart';

/// Đếm số phòng đang chiếm quota gói — mỗi property đóng góp `roomCount ?? 1`.
class PropertyRoomCounter {
  PropertyRoomCounter._();

  static int fromHomestays(Iterable<HomestayModel> homestays) {
    var total = 0;
    for (final h in homestays) {
      if (!h.isActive) continue;
      total += h.roomCount ?? 1;
    }
    return total;
  }
}
