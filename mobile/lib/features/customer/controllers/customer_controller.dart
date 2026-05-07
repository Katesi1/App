import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../calendar/controllers/calendar_controller.dart';

// ── Repository provider ────────────────────────────────────────────────────

final customerRepositoryProvider =
    Provider<CustomerRepository>((ref) => CustomerRepository());

// ── Public rooms (cho customer tìm phòng) ──────────────────────────────────

final publicRoomsProvider =
    FutureProvider.family<List<RoomModel>, PublicRoomFilter?>(
        (ref, filter) async {
  final repo = ref.read(customerRepositoryProvider);
  final result = await repo.getPublicRooms(
    checkinDate: filter?.checkinDate,
    checkoutDate: filter?.checkoutDate,
    guests: filter?.guests,
    minPrice: filter?.minPrice,
    maxPrice: filter?.maxPrice,
    view: filter?.view,
  );
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ── My bookings (booking của customer) ─────────────────────────────────────

final myBookingsProvider =
    FutureProvider.family<List<BookingModel>, int?>((ref, status) async {
  final repo = ref.read(customerRepositoryProvider);
  final result = await repo.getMyBookings(status: status);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ── Customer actions (hold, cancel) ────────────────────────────────────────

class CustomerBookingNotifier extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repo;
  final Ref _ref;

  CustomerBookingNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  void _refreshAll() {
    _ref.invalidate(myBookingsProvider);
    _ref.invalidate(publicRoomsProvider);
    _ref.invalidate(calendarGridProvider);
  }

  Future<bool> holdRoom(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.customerHoldRoom(data);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> cancelBooking(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.customerCancelBooking(id);
    if (result.success) {
      _refreshAll();
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final customerBookingProvider =
    StateNotifierProvider<CustomerBookingNotifier, AsyncValue<void>>((ref) {
  return CustomerBookingNotifier(
    ref.read(customerRepositoryProvider),
    ref,
  );
});

// ── Filter model ───────────────────────────────────────────────────────────

class PublicRoomFilter {
  final DateTime? checkinDate;
  final DateTime? checkoutDate;
  final int? guests;
  final double? minPrice;
  final double? maxPrice;
  final String? view; // "sea", "city", null

  const PublicRoomFilter({
    this.checkinDate,
    this.checkoutDate,
    this.guests,
    this.minPrice,
    this.maxPrice,
    this.view,
  });
}
