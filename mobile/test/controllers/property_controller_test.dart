import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/models/booking_model.dart';
import 'package:mobile/data/models/calendar_model.dart';
import 'package:mobile/data/models/homestay_model.dart';
import 'package:mobile/data/models/room_model.dart';
import 'package:mobile/data/repositories/booking_repository.dart';
import 'package:mobile/data/repositories/calendar_repository.dart';
import 'package:mobile/data/repositories/dashboard_repository.dart';
import 'package:mobile/data/repositories/homestay_repository.dart';
import 'package:mobile/data/repositories/report_repository.dart';
import 'package:mobile/data/repositories/room_repository.dart';
import 'package:mobile/features/bookings/controllers/booking_controller.dart';
import 'package:mobile/features/calendar/controllers/calendar_controller.dart';
import 'package:mobile/features/dashboard/controllers/dashboard_controller.dart';
import 'package:mobile/features/properties/controllers/property_controller.dart';
import 'package:mobile/features/reports/controllers/report_controller.dart';
import 'package:mobile/features/rooms/controllers/room_controller.dart';

// ─── Fake HomestayRepository ──────────────────────────────────────────────────

class FakeHomestayRepository extends HomestayRepository {
  ApiResponse<List<HomestayModel>>? getHomestaysResult;
  ApiResponse<HomestayModel>? getHomestayResult;
  ApiResponse<HomestayModel>? createHomestayResult;
  ApiResponse<HomestayModel>? updateHomestayResult;
  ApiResponse<void>? deleteHomestayResult;

  @override
  Future<ApiResponse<List<HomestayModel>>> getHomestays({
    bool includeInactive = false,
  }) async =>
      getHomestaysResult ??
      ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<HomestayModel>> getHomestay(String id) async =>
      getHomestayResult ??
      ApiResponse(success: true, data: _fakeHomestay(id), message: '');

  @override
  Future<ApiResponse<HomestayModel>> createHomestay(
    Map<String, dynamic> data,
  ) async =>
      createHomestayResult ??
      ApiResponse(
        success: true,
        data: _fakeHomestay('new-homestay'),
        message: 'Tạo cơ sở thành công',
      );

  @override
  Future<ApiResponse<HomestayModel>> updateHomestay(
    String id,
    Map<String, dynamic> data,
  ) async =>
      updateHomestayResult ??
      ApiResponse(
        success: true,
        data: _fakeHomestay(id),
        message: 'Cập nhật thành công',
      );

  @override
  Future<ApiResponse<void>> deleteHomestay(String id) async =>
      deleteHomestayResult ??
      ApiResponse(success: true, message: 'Xoá cơ sở thành công');
}

// ─── Fake: side-effect repositories (prevent post-invalidation re-fetch errors)

class _FakeRoomRepository extends RoomRepository {
  @override
  Future<ApiResponse<List<RoomModel>>> getRooms({
    String? homestayId,
    bool includeInactive = true,
  }) async =>
      ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<List<RoomModel>>> getAllPublicRooms() async =>
      ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<RoomModel>> getRoomDetail(String id) async =>
      ApiResponse(
        success: true,
        data: RoomModel(id: id, homestayId: 'h1', name: 'Room', code: 'R'),
        message: '',
      );

  @override
  Future<ApiResponse<RoomModel>> createRoom(
    Map<String, dynamic> data,
  ) async =>
      ApiResponse(
        success: true,
        data: RoomModel(
          id: 'r-new',
          homestayId: 'h1',
          name: 'New',
          code: 'R-NEW',
        ),
        message: '',
      );

  @override
  Future<ApiResponse<RoomModel>> updateRoom(
    String id,
    Map<String, dynamic> data,
  ) async =>
      ApiResponse(
        success: true,
        data: RoomModel(id: id, homestayId: 'h1', name: 'Updated', code: 'R'),
        message: '',
      );

  @override
  Future<ApiResponse<void>> deleteRoom(String id) async =>
      ApiResponse(success: true, message: '');

  @override
  Future<ApiResponse<List<RoomImageModel>>> uploadImages(
    String roomId,
    List<String> filePaths,
  ) async =>
      ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<void>> deleteImage(
    String roomId,
    String imageId,
  ) async =>
      ApiResponse(success: true, message: '');

  @override
  Future<ApiResponse<void>> setCoverImage(
    String roomId,
    String imageId,
  ) async =>
      ApiResponse(success: true, message: '');

  @override
  Future<ApiResponse<Map<String, dynamic>>> upsertPrice(
    String roomId,
    Map<String, dynamic> data,
  ) async =>
      ApiResponse(success: true, data: {}, message: '');
}

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

class _FakeBookingRepository extends BookingRepository {
  @override
  Future<ApiResponse<List<BookingModel>>> getBookings({
    String? propertyId,
  }) async =>
      ApiResponse(success: true, data: [], message: '');
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

HomestayModel _fakeHomestay(String id) => HomestayModel(
      id: id,
      ownerId: 'owner-1',
      name: 'Homestay $id',
      address: '123 Hạ Long',
    );

ProviderContainer _makeContainer(FakeHomestayRepository repo) {
  return ProviderContainer(
    overrides: [
      homestayRepositoryProvider.overrideWithValue(repo),
      roomRepositoryProvider.overrideWithValue(_FakeRoomRepository()),
      dashboardRepositoryProvider
          .overrideWithValue(_FakeDashboardRepository()),
      reportRepositoryProvider.overrideWithValue(_FakeReportRepository()),
      bookingRepositoryProvider.overrideWithValue(_FakeBookingRepository()),
      calendarRepositoryProvider.overrideWithValue(_FakeCalendarRepository()),
    ],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── homestayListProvider ────────────────────────────────────────────────────
  group('homestayListProvider', () {
    test('returns list of homestays on success', () async {
      final repo = FakeHomestayRepository()
        ..getHomestaysResult = ApiResponse(
          success: true,
          data: [_fakeHomestay('h1'), _fakeHomestay('h2')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result =
          await container.read(homestayListProvider(true).future);

      expect(result, hasLength(2));
      expect(result.first.id, 'h1');
      expect(result.last.id, 'h2');
    });

    test('throws Exception when success is false', () async {
      final repo = FakeHomestayRepository()
        ..getHomestaysResult = ApiResponse(
          success: false,
          message: 'Không có quyền truy cập',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(homestayListProvider(false).future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeHomestayRepository()
        ..getHomestaysResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(homestayListProvider(true).future),
        throwsA(isA<Exception>()),
      );
    });

    test('includeInactive=true and false are independent providers', () async {
      final repo = FakeHomestayRepository()
        ..getHomestaysResult = ApiResponse(
          success: true,
          data: [_fakeHomestay('h-active')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final active = await container.read(homestayListProvider(false).future);
      final all = await container.read(homestayListProvider(true).future);

      expect(active.first.id, 'h-active');
      expect(all.first.id, 'h-active');
    });
  });

  // ── homestayDetailProvider ──────────────────────────────────────────────────
  group('homestayDetailProvider', () {
    test('returns HomestayModel on success', () async {
      final repo = FakeHomestayRepository()
        ..getHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('detail-1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result =
          await container.read(homestayDetailProvider('detail-1').future);

      expect(result.id, 'detail-1');
      expect(result.ownerId, 'owner-1');
      expect(result.name, 'Homestay detail-1');
    });

    test('throws Exception when success is false', () async {
      final repo = FakeHomestayRepository()
        ..getHomestayResult = ApiResponse(
          success: false,
          message: 'Cơ sở không tồn tại',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(homestayDetailProvider('missing').future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeHomestayRepository()
        ..getHomestayResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(homestayDetailProvider('any').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── HomestayActionsNotifier — initial state ─────────────────────────────────
  group('HomestayActionsNotifier initial state', () {
    test('initial state is AsyncData(null)', () {
      final container = _makeContainer(FakeHomestayRepository());
      addTearDown(container.dispose);

      expect(
        container.read(homestayActionsProvider),
        isA<AsyncData<void>>(),
      );
    });
  });

  // ── HomestayActionsNotifier.create ──────────────────────────────────────────
  group('HomestayActionsNotifier.create', () {
    test('returns non-null id string and state is AsyncData on success',
        () async {
      final repo = FakeHomestayRepository()
        ..createHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('created-h1'),
          message: 'Tạo cơ sở thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final id = await container
          .read(homestayActionsProvider.notifier)
          .create({'name': 'Homestay mới', 'address': '1 Hạ Long'});

      expect(id, isNotNull);
      expect(id, 'created-h1');
      expect(container.read(homestayActionsProvider), isA<AsyncData<void>>());
    });

    test('returns null and state is AsyncError on failure', () async {
      final repo = FakeHomestayRepository()
        ..createHomestayResult = ApiResponse(
          success: false,
          message: 'Tên cơ sở đã tồn tại',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final id = await container
          .read(homestayActionsProvider.notifier)
          .create({'name': 'Trùng tên'});

      expect(id, isNull);
      final state = container.read(homestayActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Tên cơ sở đã tồn tại'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeHomestayRepository()
        ..createHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('h-new'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(homestayActionsProvider.notifier).create({});

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeHomestayRepository()
        ..createHomestayResult = ApiResponse(
          success: false,
          message: 'Lỗi server',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(homestayActionsProvider.notifier).create({});

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });
  });

  // ── HomestayActionsNotifier.update ──────────────────────────────────────────
  group('HomestayActionsNotifier.update', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('h-upd'),
          message: 'Cập nhật thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(homestayActionsProvider.notifier)
          .update('h-upd', {'name': 'Tên mới'});

      expect(result, isTrue);
      expect(container.read(homestayActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: false,
          message: 'Không có quyền sửa cơ sở',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(homestayActionsProvider.notifier)
          .update('h-no-perm', {});

      expect(result, isFalse);
      final state = container.read(homestayActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Không có quyền sửa cơ sở'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('h-u1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(homestayActionsProvider.notifier)
          .update('h-u1', {'address': 'Địa chỉ mới'});

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: false,
          message: 'Lỗi cập nhật',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(homestayActionsProvider.notifier)
          .update('h-fail', {});

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });
  });

  // ── HomestayActionsNotifier.toggleActive ────────────────────────────────────
  group('HomestayActionsNotifier.toggleActive', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('h-toggle'),
          message: 'Cập nhật trạng thái thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(homestayActionsProvider.notifier)
          .toggleActive('h-toggle', false);

      expect(result, isTrue);
      expect(container.read(homestayActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: false,
          message: 'Không thể tắt cơ sở đang có khách ở',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(homestayActionsProvider.notifier)
          .toggleActive('h-occupied', false);

      expect(result, isFalse);
      final state = container.read(homestayActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Không thể tắt cơ sở đang có khách ở'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('h-t1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(homestayActionsProvider.notifier)
          .toggleActive('h-t1', true);

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeHomestayRepository()
        ..updateHomestayResult = ApiResponse(
          success: false,
          message: 'Lỗi toggle',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(homestayActionsProvider.notifier)
          .toggleActive('h-t2', false);

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });
  });

  // ── HomestayActionsNotifier.delete ──────────────────────────────────────────
  group('HomestayActionsNotifier.delete', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeHomestayRepository()
        ..deleteHomestayResult = ApiResponse(
          success: true,
          message: 'Xoá cơ sở thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(homestayActionsProvider.notifier)
          .delete('h-del');

      expect(result, isTrue);
      expect(container.read(homestayActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeHomestayRepository()
        ..deleteHomestayResult = ApiResponse(
          success: false,
          message: 'Cơ sở đang có phòng hoạt động',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(homestayActionsProvider.notifier)
          .delete('h-has-rooms');

      expect(result, isFalse);
      final state = container.read(homestayActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Cơ sở đang có phòng hoạt động'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeHomestayRepository()
        ..deleteHomestayResult = ApiResponse(
          success: true,
          message: 'Xoá thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(homestayActionsProvider.notifier).delete('h-d1');

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeHomestayRepository()
        ..deleteHomestayResult = ApiResponse(
          success: false,
          message: 'Lỗi xoá',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        homestayActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(homestayActionsProvider.notifier).delete('h-d2');

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });
  });

  // ── Sequential operations ───────────────────────────────────────────────────
  group('HomestayActionsNotifier sequential operations', () {
    test('state resets to AsyncData after two consecutive successes', () async {
      final repo = FakeHomestayRepository()
        ..createHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('seq-1'),
          message: '',
        )
        ..updateHomestayResult = ApiResponse(
          success: true,
          data: _fakeHomestay('seq-1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(homestayActionsProvider.notifier);

      await notifier.create({});
      expect(container.read(homestayActionsProvider), isA<AsyncData<void>>());

      await notifier.update('seq-1', {});
      expect(container.read(homestayActionsProvider), isA<AsyncData<void>>());
    });

    test('after error, next success resets state to AsyncData', () async {
      final repo = FakeHomestayRepository()
        ..deleteHomestayResult = ApiResponse(
          success: false,
          message: 'Lỗi xoá',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(homestayActionsProvider.notifier);

      await notifier.delete('h-fail');
      expect(container.read(homestayActionsProvider), isA<AsyncError<void>>());

      repo.deleteHomestayResult = ApiResponse(
        success: true,
        message: 'Xoá thành công',
      );
      await notifier.delete('h-ok');
      expect(container.read(homestayActionsProvider), isA<AsyncData<void>>());
    });
  });
}
