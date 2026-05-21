import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/models/booking_model.dart';
import 'package:mobile/data/repositories/booking_repository.dart';
import 'package:mobile/data/models/calendar_model.dart';
import 'package:mobile/data/repositories/calendar_repository.dart';
import 'package:mobile/data/repositories/dashboard_repository.dart';
import 'package:mobile/data/repositories/report_repository.dart';
import 'package:mobile/features/bookings/controllers/booking_controller.dart';
import 'package:mobile/features/calendar/controllers/calendar_controller.dart';
import 'package:mobile/features/dashboard/controllers/dashboard_controller.dart';
import 'package:mobile/features/reports/controllers/report_controller.dart';

// ─── Fake: booking ────────────────────────────────────────────────────────────

class FakeBookingRepository extends BookingRepository {
  ApiResponse<List<BookingModel>>? getBookingsResult;
  ApiResponse<BookingModel>? getBookingDetailResult;
  ApiResponse<BookingModel>? holdRoomResult;
  ApiResponse<BookingModel>? confirmBookingResult;
  ApiResponse<void>? cancelBookingResult;
  ApiResponse<BookingModel>? updateBookingResult;
  ApiResponse<List<CalendarBooking>>? getCalendarResult;

  @override
  Future<ApiResponse<List<BookingModel>>> getBookings({
    String? propertyId,
  }) async =>
      getBookingsResult ?? ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<BookingModel>> getBookingDetail(String id) async =>
      getBookingDetailResult ??
      ApiResponse(success: true, data: _fakeBooking(id), message: '');

  @override
  Future<ApiResponse<BookingModel>> holdRoom(
    Map<String, dynamic> data,
  ) async =>
      holdRoomResult ??
      ApiResponse(
        success: true,
        data: _fakeBooking('new-booking-1'),
        message: 'Hold thành công',
      );

  @override
  Future<ApiResponse<BookingModel>> confirmBooking(String id) async =>
      confirmBookingResult ??
      ApiResponse(
        success: true,
        data: _fakeBooking(id),
        message: 'Xác nhận thành công',
      );

  @override
  Future<ApiResponse<void>> cancelBooking(String id) async =>
      cancelBookingResult ??
      ApiResponse(success: true, message: 'Huỷ booking thành công');

  @override
  Future<ApiResponse<BookingModel>> updateBooking(
    String id,
    Map<String, dynamic> data,
  ) async =>
      updateBookingResult ??
      ApiResponse(
        success: true,
        data: _fakeBooking(id),
        message: 'Cập nhật thành công',
      );

  @override
  Future<ApiResponse<List<CalendarBooking>>> getCalendar(
    String propertyId,
    int year,
    int month,
  ) async =>
      getCalendarResult ??
      ApiResponse(success: true, data: [], message: '');
}

// ─── Fake: downstream repos (prevent network hits when providers invalidate) ──

class _FakeDashboardRepository extends DashboardRepository {
  @override
  Future<ApiResponse<Map<String, dynamic>>> getStats() async =>
      ApiResponse(success: true, data: {}, message: '');
}

class _FakeReportRepository extends ReportRepository {
  @override
  Future<ApiResponse<Map<String, dynamic>>> getReport({
    String? period,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) async =>
      ApiResponse(success: true, data: {}, message: '');
}

class _FakeCalendarRepository extends CalendarRepository {
  @override
  Future<ApiResponse<CalendarGrid>> getPublicGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async =>
      ApiResponse(
        success: true,
        data: const CalendarGrid(),
        message: '',
      );

  @override
  Future<ApiResponse<CalendarGrid>> getGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async =>
      ApiResponse(
        success: true,
        data: const CalendarGrid(),
        message: '',
      );
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

BookingModel _fakeBooking(String id) => BookingModel(
      id: id,
      propertyId: 'property-1',
      checkinDate: DateTime(2026, 6, 1),
      checkoutDate: DateTime(2026, 6, 3),
      status: BookingStatus.hold,
    );

ProviderContainer _makeContainer(FakeBookingRepository repo) {
  return ProviderContainer(
    overrides: [
      bookingRepositoryProvider.overrideWithValue(repo),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      reportRepositoryProvider.overrideWithValue(_FakeReportRepository()),
      calendarRepositoryProvider.overrideWithValue(_FakeCalendarRepository()),
    ],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  // ── CalendarParams ──────────────────────────────────────────────────────────
  group('CalendarParams', () {
    test('equal when same propertyId, year, month', () {
      const a = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      const b = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      expect(a, equals(b));
    });

    test('not equal when propertyId differs', () {
      const a = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      const b = CalendarParams(propertyId: 'p2', year: 2026, month: 5);
      expect(a, isNot(equals(b)));
    });

    test('not equal when year differs', () {
      const a = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      const b = CalendarParams(propertyId: 'p1', year: 2025, month: 5);
      expect(a, isNot(equals(b)));
    });

    test('not equal when month differs', () {
      const a = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      const b = CalendarParams(propertyId: 'p1', year: 2026, month: 6);
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent for equal instances', () {
      const a = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      const b = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for unequal instances', () {
      const a = CalendarParams(propertyId: 'p1', year: 2026, month: 5);
      const b = CalendarParams(propertyId: 'p2', year: 2026, month: 5);
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  // ── bookingListProvider ─────────────────────────────────────────────────────
  group('bookingListProvider', () {
    test('returns list on success', () async {
      final repo = FakeBookingRepository()
        ..getBookingsResult = ApiResponse(
          success: true,
          data: [_fakeBooking('b1'), _fakeBooking('b2')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(bookingListProvider(null).future);

      expect(result, hasLength(2));
      expect(result.first.id, 'b1');
    });

    test('filters by propertyId (passes param through)', () async {
      final repo = FakeBookingRepository()
        ..getBookingsResult = ApiResponse(
          success: true,
          data: [_fakeBooking('b-scoped')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        bookingListProvider('property-X').future,
      );

      expect(result.single.id, 'b-scoped');
    });

    test('throws when success is false', () async {
      final repo = FakeBookingRepository()
        ..getBookingsResult = ApiResponse(
          success: false,
          message: 'Lỗi kết nối',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(bookingListProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeBookingRepository()
        ..getBookingsResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(bookingListProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── bookingDetailProvider ───────────────────────────────────────────────────
  group('bookingDetailProvider', () {
    test('returns booking on success', () async {
      final repo = FakeBookingRepository()
        ..getBookingDetailResult = ApiResponse(
          success: true,
          data: _fakeBooking('detail-1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result =
          await container.read(bookingDetailProvider('detail-1').future);

      expect(result.id, 'detail-1');
      expect(result.propertyId, 'property-1');
    });

    test('throws when success is false', () async {
      final repo = FakeBookingRepository()
        ..getBookingDetailResult = ApiResponse(
          success: false,
          message: 'Booking không tồn tại',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(bookingDetailProvider('missing').future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeBookingRepository()
        ..getBookingDetailResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(bookingDetailProvider('any').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── BookingActionsNotifier.hold ─────────────────────────────────────────────
  group('BookingActionsNotifier.hold', () {
    test('initial state is AsyncData(null)', () {
      final container = _makeContainer(FakeBookingRepository());
      addTearDown(container.dispose);

      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());
    });

    test('returns true and state becomes AsyncData on success', () async {
      final repo = FakeBookingRepository()
        ..holdRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('hold-1'),
          message: 'OK',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .hold({'propertyId': 'p1', 'checkinDate': '2026-06-01'});

      expect(result, isTrue);
      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state becomes AsyncError on failure', () async {
      final repo = FakeBookingRepository()
        ..holdRoomResult = ApiResponse(
          success: false,
          message: 'Phòng đã được đặt',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .hold({'propertyId': 'p1'});

      expect(result, isFalse);
      final state = container.read(bookingActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Phòng đã được đặt'),
      );
    });

    test('state transitions through loading then data on success', () async {
      final repo = FakeBookingRepository()
        ..holdRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('h-1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        bookingActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(bookingActionsProvider.notifier).hold({});

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });
  });

  // ── BookingActionsNotifier.confirm ──────────────────────────────────────────
  group('BookingActionsNotifier.confirm', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeBookingRepository()
        ..confirmBookingResult = ApiResponse(
          success: true,
          data: _fakeBooking('b-confirm'),
          message: 'Đã xác nhận',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .confirm('b-confirm');

      expect(result, isTrue);
      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeBookingRepository()
        ..confirmBookingResult = ApiResponse(
          success: false,
          message: 'Không thể xác nhận',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .confirm('b-err');

      expect(result, isFalse);
      expect(container.read(bookingActionsProvider), isA<AsyncError<void>>());
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeBookingRepository()
        ..confirmBookingResult = ApiResponse(
          success: true,
          data: _fakeBooking('b1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        bookingActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(bookingActionsProvider.notifier).confirm('b1');

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });
  });

  // ── BookingActionsNotifier.cancel ───────────────────────────────────────────
  group('BookingActionsNotifier.cancel', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeBookingRepository()
        ..cancelBookingResult = ApiResponse(
          success: true,
          message: 'Huỷ booking thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .cancel('b-cancel');

      expect(result, isTrue);
      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeBookingRepository()
        ..cancelBookingResult = ApiResponse(
          success: false,
          message: 'Booking đang được xử lý',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .cancel('b-locked');

      expect(result, isFalse);
      final state = container.read(bookingActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Booking đang được xử lý'),
      );
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeBookingRepository()
        ..cancelBookingResult = ApiResponse(
          success: false,
          message: 'Lỗi',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        bookingActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(bookingActionsProvider.notifier).cancel('x');

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });
  });

  // ── BookingActionsNotifier.update ───────────────────────────────────────────
  group('BookingActionsNotifier.update', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeBookingRepository()
        ..updateBookingResult = ApiResponse(
          success: true,
          data: _fakeBooking('b-upd'),
          message: 'Cập nhật thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .update('b-upd', {'notes': 'Ghi chú mới'});

      expect(result, isTrue);
      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeBookingRepository()
        ..updateBookingResult = ApiResponse(
          success: false,
          message: 'Dữ liệu không hợp lệ',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(bookingActionsProvider.notifier)
          .update('b-err', {});

      expect(result, isFalse);
      final state = container.read(bookingActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Dữ liệu không hợp lệ'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeBookingRepository()
        ..updateBookingResult = ApiResponse(
          success: true,
          data: _fakeBooking('u1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        bookingActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(bookingActionsProvider.notifier)
          .update('u1', {'guestCount': 3});

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('error message is preserved in AsyncError state', () async {
      const errorMsg = 'Ngày checkin không hợp lệ';
      final repo = FakeBookingRepository()
        ..updateBookingResult = ApiResponse(
          success: false,
          message: errorMsg,
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container
          .read(bookingActionsProvider.notifier)
          .update('b1', {'checkinDate': 'invalid'});

      final state = container.read(bookingActionsProvider);
      expect((state as AsyncError).error.toString(), contains(errorMsg));
    });
  });

  // ── Sequential operations ───────────────────────────────────────────────────
  group('BookingActionsNotifier sequential operations', () {
    test('state resets to AsyncData after two consecutive successes', () async {
      final repo = FakeBookingRepository()
        ..holdRoomResult = ApiResponse(
          success: true,
          data: _fakeBooking('seq-1'),
          message: '',
        )
        ..confirmBookingResult = ApiResponse(
          success: true,
          data: _fakeBooking('seq-1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(bookingActionsProvider.notifier);

      await notifier.hold({});
      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());

      await notifier.confirm('seq-1');
      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());
    });

    test('after error, next success resets state to AsyncData', () async {
      final repo = FakeBookingRepository()
        ..holdRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi lần 1',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(bookingActionsProvider.notifier);

      await notifier.hold({});
      expect(container.read(bookingActionsProvider), isA<AsyncError<void>>());

      repo.holdRoomResult = ApiResponse(
        success: true,
        data: _fakeBooking('retry-ok'),
        message: '',
      );
      await notifier.hold({});
      expect(container.read(bookingActionsProvider), isA<AsyncData<void>>());
    });
  });
}
