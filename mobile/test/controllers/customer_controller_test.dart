import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/models/booking_model.dart';
import 'package:mobile/data/models/calendar_model.dart';
import 'package:mobile/data/models/room_model.dart';
import 'package:mobile/data/repositories/calendar_repository.dart';
import 'package:mobile/data/repositories/customer_repository.dart';
import 'package:mobile/features/calendar/controllers/calendar_controller.dart';
import 'package:mobile/features/customer/controllers/customer_controller.dart';

// ─── Fake: CustomerRepository ─────────────────────────────────────────────────

class FakeCustomerRepository extends CustomerRepository {
  ApiResponse<List<RoomModel>>? getPublicRoomsResult;
  ApiResponse<List<BookingModel>>? getMyBookingsResult;
  ApiResponse<BookingModel>? customerHoldRoomResult;
  ApiResponse<void>? customerCancelBookingResult;

  // Capture last-called params for assertion
  DateTime? lastCheckinDate;
  DateTime? lastCheckoutDate;
  int? lastGuests;
  double? lastMinPrice;
  double? lastMaxPrice;
  String? lastView;
  int? lastStatus;
  String? lastCancelledId;

  @override
  Future<ApiResponse<List<RoomModel>>> getPublicRooms({
    DateTime? checkinDate,
    DateTime? checkoutDate,
    int? guests,
    double? minPrice,
    double? maxPrice,
    String? view,
  }) async {
    lastCheckinDate = checkinDate;
    lastCheckoutDate = checkoutDate;
    lastGuests = guests;
    lastMinPrice = minPrice;
    lastMaxPrice = maxPrice;
    lastView = view;
    return getPublicRoomsResult ??
        ApiResponse(success: true, data: [], message: '');
  }

  @override
  Future<ApiResponse<List<BookingModel>>> getMyBookings({
    int? status,
  }) async {
    lastStatus = status;
    return getMyBookingsResult ??
        ApiResponse(success: true, data: [], message: '');
  }

  @override
  Future<ApiResponse<BookingModel>> customerHoldRoom(
    Map<String, dynamic> data,
  ) async =>
      customerHoldRoomResult ??
      ApiResponse(
        success: true,
        data: _fakeBooking('new-hold-1'),
        message: 'Đặt phòng thành công',
      );

  @override
  Future<ApiResponse<void>> customerCancelBooking(String id) async {
    lastCancelledId = id;
    return customerCancelBookingResult ??
        ApiResponse(success: true, message: 'Đã huỷ đặt phòng');
  }
}

// ─── Fake: CalendarRepository (prevent network hits when calendarGridProvider
//     is invalidated by _refreshAll) ──────────────────────────────────────────

class _FakeCalendarRepository extends CalendarRepository {
  @override
  Future<ApiResponse<CalendarGrid>> getPublicGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async =>
      ApiResponse(success: true, data: const CalendarGrid(), message: '');

  @override
  Future<ApiResponse<CalendarGrid>> getGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async =>
      ApiResponse(success: true, data: const CalendarGrid(), message: '');
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

RoomModel _fakeRoom(String id) => RoomModel(
      id: id,
      homestayId: 'homestay-1',
      name: 'Phòng $id',
      code: 'R$id',
      isActive: true,
    );

BookingModel _fakeBooking(String id) => BookingModel(
      id: id,
      propertyId: 'property-1',
      checkinDate: DateTime(2026, 6, 1),
      checkoutDate: DateTime(2026, 6, 3),
      status: BookingStatus.hold,
    );

ProviderContainer _makeContainer(FakeCustomerRepository repo) {
  return ProviderContainer(
    overrides: [
      customerRepositoryProvider.overrideWithValue(repo),
      calendarRepositoryProvider.overrideWithValue(_FakeCalendarRepository()),
    ],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  // ── PublicRoomFilter ────────────────────────────────────────────────────────
  group('PublicRoomFilter', () {
    test('default constructor has all fields null', () {
      const filter = PublicRoomFilter();

      expect(filter.checkinDate, isNull);
      expect(filter.checkoutDate, isNull);
      expect(filter.guests, isNull);
      expect(filter.minPrice, isNull);
      expect(filter.maxPrice, isNull);
      expect(filter.view, isNull);
    });

    test('stores all provided values correctly', () {
      final checkin = DateTime(2026, 6, 1);
      final checkout = DateTime(2026, 6, 3);
      final filter = PublicRoomFilter(
        checkinDate: checkin,
        checkoutDate: checkout,
        guests: 3,
        minPrice: 500000,
        maxPrice: 2000000,
        view: 'sea',
      );

      expect(filter.checkinDate, checkin);
      expect(filter.checkoutDate, checkout);
      expect(filter.guests, 3);
      expect(filter.minPrice, 500000);
      expect(filter.maxPrice, 2000000);
      expect(filter.view, 'sea');
    });

    test('two instances with same values are equal (Equatable)', () {
      final checkin = DateTime(2026, 6, 1);
      final a = PublicRoomFilter(checkinDate: checkin, guests: 2);
      final b = PublicRoomFilter(checkinDate: checkin, guests: 2);

      expect(a, equals(b));
    });

    test('two instances with different values are not equal', () {
      const a = PublicRoomFilter(guests: 2);
      const b = PublicRoomFilter(guests: 3);

      expect(a, isNot(equals(b)));
    });

    test('equal instances have same hashCode', () {
      final checkin = DateTime(2026, 6, 1);
      final a = PublicRoomFilter(checkinDate: checkin, minPrice: 100000);
      final b = PublicRoomFilter(checkinDate: checkin, minPrice: 100000);

      expect(a.hashCode, equals(b.hashCode));
    });

    test('null filter equals another null filter (both default)', () {
      const a = PublicRoomFilter();
      const b = PublicRoomFilter();

      expect(a, equals(b));
    });

    test('view field distinguishes filters', () {
      const a = PublicRoomFilter(view: 'sea');
      const b = PublicRoomFilter(view: 'city');

      expect(a, isNot(equals(b)));
    });
  });

  // ── publicRoomsProvider ─────────────────────────────────────────────────────
  group('publicRoomsProvider', () {
    test('returns list on success', () async {
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: [_fakeRoom('r1'), _fakeRoom('r2')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(publicRoomsProvider(null).future);

      expect(result, hasLength(2));
      expect(result.first.id, 'r1');
      expect(result.last.id, 'r2');
    });

    test('returns empty list when repo returns empty', () async {
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(publicRoomsProvider(null).future);

      expect(result, isEmpty);
    });

    test('throws Exception on failure', () async {
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: false,
          message: 'Không kết nối được server',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(publicRoomsProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('error message is preserved in exception', () async {
      const errorMsg = 'Lỗi máy chủ (500).';
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: false,
          message: errorMsg,
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(publicRoomsProvider(null).future),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(errorMsg),
          ),
        ),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(publicRoomsProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('passes filter params to repository', () async {
      final checkin = DateTime(2026, 7, 1);
      final checkout = DateTime(2026, 7, 5);
      final filter = PublicRoomFilter(
        checkinDate: checkin,
        checkoutDate: checkout,
        guests: 4,
        minPrice: 300000,
        maxPrice: 1500000,
        view: 'sea',
      );
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(publicRoomsProvider(filter).future);

      expect(repo.lastCheckinDate, checkin);
      expect(repo.lastCheckoutDate, checkout);
      expect(repo.lastGuests, 4);
      expect(repo.lastMinPrice, 300000);
      expect(repo.lastMaxPrice, 1500000);
      expect(repo.lastView, 'sea');
    });

    test('passes null params when filter is null', () async {
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(publicRoomsProvider(null).future);

      expect(repo.lastCheckinDate, isNull);
      expect(repo.lastCheckoutDate, isNull);
      expect(repo.lastGuests, isNull);
      expect(repo.lastMinPrice, isNull);
      expect(repo.lastMaxPrice, isNull);
      expect(repo.lastView, isNull);
    });

    test('two different filters create independent providers', () async {
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: [_fakeRoom('sea-room')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      const filterA = PublicRoomFilter(view: 'sea');
      const filterB = PublicRoomFilter(view: 'city');

      // Both can be read without conflict
      final resultA = await container.read(publicRoomsProvider(filterA).future);
      final resultB = await container.read(publicRoomsProvider(filterB).future);

      expect(resultA, isA<List<RoomModel>>());
      expect(resultB, isA<List<RoomModel>>());
    });
  });

  // ── myBookingsProvider ──────────────────────────────────────────────────────
  group('myBookingsProvider', () {
    test('returns list on success', () async {
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [_fakeBooking('bk1'), _fakeBooking('bk2')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(myBookingsProvider(null).future);

      expect(result, hasLength(2));
      expect(result.first.id, 'bk1');
    });

    test('returns empty list when no bookings', () async {
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(myBookingsProvider(null).future);

      expect(result, isEmpty);
    });

    test('throws Exception on failure', () async {
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: false,
          message: 'Phiên đăng nhập hết hạn',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(myBookingsProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('error message is preserved in exception', () async {
      const errorMsg = 'Không có quyền truy cập';
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: false,
          message: errorMsg,
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(myBookingsProvider(null).future),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(errorMsg),
          ),
        ),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(myBookingsProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('passes status param to repository', () async {
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [_fakeBooking('hold-bk')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(myBookingsProvider(1).future);

      expect(repo.lastStatus, 1);
    });

    test('passes null status when not filtered', () async {
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(myBookingsProvider(null).future);

      expect(repo.lastStatus, isNull);
    });

    test('different status params create independent providers', () async {
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final allBookings = await container.read(myBookingsProvider(null).future);
      final holdBookings = await container.read(myBookingsProvider(1).future);

      expect(allBookings, isA<List<BookingModel>>());
      expect(holdBookings, isA<List<BookingModel>>());
    });
  });

  // ── CustomerBookingNotifier — initial state ─────────────────────────────────
  group('CustomerBookingNotifier initial state', () {
    test('initial state is AsyncData(null)', () {
      final container = _makeContainer(FakeCustomerRepository());
      addTearDown(container.dispose);

      expect(
        container.read(customerBookingProvider),
        isA<AsyncData<void>>(),
      );
    });
  });

  // ── CustomerBookingNotifier.holdRoom ────────────────────────────────────────
  group('CustomerBookingNotifier.holdRoom', () {
    test('returns true and state becomes AsyncData on success', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('hold-ok'),
          message: 'Đặt phòng thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(customerBookingProvider.notifier)
          .holdRoom({'propertyId': 'p1', 'checkinDate': '2026-06-01'});

      expect(result, isTrue);
      expect(container.read(customerBookingProvider), isA<AsyncData<void>>());
    });

    test('returns false and state becomes AsyncError on failure', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: false,
          message: 'Phòng đã được đặt',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(customerBookingProvider.notifier)
          .holdRoom({'propertyId': 'p1'});

      expect(result, isFalse);
      final state = container.read(customerBookingProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Phòng đã được đặt'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('h1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        customerBookingProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(customerBookingProvider.notifier).holdRoom({});

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        customerBookingProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(customerBookingProvider.notifier).holdRoom({});

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });

    test('_refreshAll invalidates myBookingsProvider on success', () async {
      // Arrange: pre-warm myBookingsProvider with 1 item
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [_fakeBooking('pre-bk')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(myBookingsProvider(null).future);

      // Act: swap result + hold — _refreshAll should invalidate the cache
      repo
        ..customerHoldRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('h1'),
          message: '',
        )
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );

      await container
          .read(customerBookingProvider.notifier)
          .holdRoom({'propertyId': 'p1'});

      // After invalidation, re-reading fetches fresh data (empty list)
      final fresh = await container.read(myBookingsProvider(null).future);
      expect(fresh, isEmpty);
    });

    test('_refreshAll invalidates publicRoomsProvider on success', () async {
      // Arrange: pre-warm publicRoomsProvider with 1 item
      final repo = FakeCustomerRepository()
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: [_fakeRoom('pre-room')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(publicRoomsProvider(null).future);

      // Act: swap result + hold — _refreshAll should invalidate the cache
      repo
        ..customerHoldRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('h2'),
          message: '',
        )
        ..getPublicRoomsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );

      await container
          .read(customerBookingProvider.notifier)
          .holdRoom({'propertyId': 'p1'});

      // After invalidation, re-reading fetches fresh data (empty list)
      final fresh = await container.read(publicRoomsProvider(null).future);
      expect(fresh, isEmpty);
    });

    test('no _refreshAll when holdRoom fails', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: false,
          message: 'Phòng đã đặt',
        )
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      // Pre-warm myBookingsProvider
      await container.read(myBookingsProvider(null).future);

      int myBookingsRebuildCount = 0;
      container.listen(
        myBookingsProvider(null),
        (_, __) => myBookingsRebuildCount++,
        fireImmediately: false,
      );

      await container
          .read(customerBookingProvider.notifier)
          .holdRoom({'propertyId': 'p1'});

      // On failure, _refreshAll is NOT called
      expect(myBookingsRebuildCount, 0);
    });
  });

  // ── CustomerBookingNotifier.cancelBooking ───────────────────────────────────
  group('CustomerBookingNotifier.cancelBooking', () {
    test('returns true and state becomes AsyncData on success', () async {
      final repo = FakeCustomerRepository()
        ..customerCancelBookingResult = ApiResponse(
          success: true,
          message: 'Đã huỷ đặt phòng',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(customerBookingProvider.notifier)
          .cancelBooking('booking-1');

      expect(result, isTrue);
      expect(container.read(customerBookingProvider), isA<AsyncData<void>>());
    });

    test('returns false and state becomes AsyncError on failure', () async {
      final repo = FakeCustomerRepository()
        ..customerCancelBookingResult = ApiResponse(
          success: false,
          message: 'Chỉ có thể huỷ booking đang HOLD',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(customerBookingProvider.notifier)
          .cancelBooking('booking-confirmed');

      expect(result, isFalse);
      final state = container.read(customerBookingProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Chỉ có thể huỷ booking đang HOLD'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeCustomerRepository()
        ..customerCancelBookingResult = ApiResponse(
          success: true,
          message: 'Huỷ thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        customerBookingProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(customerBookingProvider.notifier)
          .cancelBooking('b-cancel');

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeCustomerRepository()
        ..customerCancelBookingResult = ApiResponse(
          success: false,
          message: 'Lỗi huỷ booking',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        customerBookingProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(customerBookingProvider.notifier)
          .cancelBooking('b-err');

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });

    test('passes correct id to repository', () async {
      final repo = FakeCustomerRepository()
        ..customerCancelBookingResult = ApiResponse(
          success: true,
          message: 'Huỷ thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container
          .read(customerBookingProvider.notifier)
          .cancelBooking('specific-id-123');

      expect(repo.lastCancelledId, 'specific-id-123');
    });

    test('_refreshAll invalidates myBookingsProvider on success', () async {
      // Arrange: pre-warm myBookingsProvider with 1 item
      final repo = FakeCustomerRepository()
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [_fakeBooking('pre-bk')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(myBookingsProvider(null).future);

      // Act: swap result + cancel — _refreshAll should invalidate the cache
      repo
        ..customerCancelBookingResult = ApiResponse(
          success: true,
          message: 'Huỷ thành công',
        )
        ..getMyBookingsResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );

      await container
          .read(customerBookingProvider.notifier)
          .cancelBooking('b-to-cancel');

      // After invalidation, re-reading fetches fresh data (empty list)
      final fresh = await container.read(myBookingsProvider(null).future);
      expect(fresh, isEmpty);
    });

    test('error message is preserved in AsyncError state', () async {
      const errorMsg = 'Booking không ở trạng thái HOLD';
      final repo = FakeCustomerRepository()
        ..customerCancelBookingResult = ApiResponse(
          success: false,
          message: errorMsg,
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container
          .read(customerBookingProvider.notifier)
          .cancelBooking('b1');

      final state = container.read(customerBookingProvider);
      expect((state as AsyncError).error.toString(), contains(errorMsg));
    });
  });

  // ── Sequential operations ───────────────────────────────────────────────────
  group('CustomerBookingNotifier sequential operations', () {
    test('state resets to AsyncData after two consecutive successes', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('seq-hold'),
          message: '',
        )
        ..customerCancelBookingResult = ApiResponse(
          success: true,
          message: 'Huỷ thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(customerBookingProvider.notifier);

      await notifier.holdRoom({'propertyId': 'p1'});
      expect(container.read(customerBookingProvider), isA<AsyncData<void>>());

      await notifier.cancelBooking('seq-hold');
      expect(container.read(customerBookingProvider), isA<AsyncData<void>>());
    });

    test('after error, next success resets state to AsyncData', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi lần 1',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(customerBookingProvider.notifier);

      await notifier.holdRoom({});
      expect(container.read(customerBookingProvider), isA<AsyncError<void>>());

      repo.customerHoldRoomResult = ApiResponse(
        success: true,
        data: _fakeBooking('retry-ok'),
        message: '',
      );

      await notifier.holdRoom({});
      expect(container.read(customerBookingProvider), isA<AsyncData<void>>());
    });

    test('holdRoom then cancelBooking changes state correctly', () async {
      final repo = FakeCustomerRepository()
        ..customerHoldRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('bk-seq'),
          message: '',
        )
        ..customerCancelBookingResult = ApiResponse(
          success: false,
          message: 'Đã quá hạn huỷ',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(customerBookingProvider.notifier);

      final holdResult = await notifier.holdRoom({'propertyId': 'p1'});
      expect(holdResult, isTrue);
      expect(container.read(customerBookingProvider), isA<AsyncData<void>>());

      final cancelResult = await notifier.cancelBooking('bk-seq');
      expect(cancelResult, isFalse);
      expect(container.read(customerBookingProvider), isA<AsyncError<void>>());
    });
  });
}
