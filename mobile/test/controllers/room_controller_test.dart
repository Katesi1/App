import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/models/room_model.dart';
import 'package:mobile/data/repositories/dashboard_repository.dart';
import 'package:mobile/data/repositories/report_repository.dart';
import 'package:mobile/data/repositories/room_repository.dart';
import 'package:mobile/features/dashboard/controllers/dashboard_controller.dart';
import 'package:mobile/features/reports/controllers/report_controller.dart';
import 'package:mobile/features/rooms/controllers/room_controller.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class FakeRoomRepository extends RoomRepository {
  ApiResponse<List<RoomModel>>? getRoomsResult;
  ApiResponse<List<RoomModel>>? getAllPublicRoomsResult;
  ApiResponse<RoomModel>? getRoomDetailResult;
  ApiResponse<RoomModel>? createRoomResult;
  ApiResponse<RoomModel>? updateRoomResult;
  ApiResponse<void>? deleteRoomResult;
  ApiResponse<List<RoomImageModel>>? uploadImagesResult;
  ApiResponse<void>? deleteImageResult;
  ApiResponse<void>? setCoverImageResult;
  ApiResponse<Map<String, dynamic>>? upsertPriceResult;

  @override
  Future<ApiResponse<List<RoomModel>>> getRooms({
    String? homestayId,
    bool includeInactive = true,
  }) async =>
      getRoomsResult ?? ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<List<RoomModel>>> getAllPublicRooms() async =>
      getAllPublicRoomsResult ??
      ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<RoomModel>> getRoomDetail(String id) async =>
      getRoomDetailResult ??
      ApiResponse(success: true, data: _fakeRoom(id), message: '');

  @override
  Future<ApiResponse<RoomModel>> createRoom(Map<String, dynamic> data) async =>
      createRoomResult ??
      ApiResponse(
        success: true,
        data: _fakeRoom('new-room'),
        message: 'Tạo phòng thành công',
      );

  @override
  Future<ApiResponse<RoomModel>> updateRoom(
    String id,
    Map<String, dynamic> data,
  ) async =>
      updateRoomResult ??
      ApiResponse(
        success: true,
        data: _fakeRoom(id),
        message: 'Cập nhật thành công',
      );

  @override
  Future<ApiResponse<void>> deleteRoom(String id) async =>
      deleteRoomResult ??
      ApiResponse(success: true, message: 'Xoá phòng thành công');

  @override
  Future<ApiResponse<List<RoomImageModel>>> uploadImages(
    String roomId,
    List<String> filePaths,
  ) async =>
      uploadImagesResult ?? ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<void>> deleteImage(
    String roomId,
    String imageId,
  ) async =>
      deleteImageResult ??
      ApiResponse(success: true, message: 'Xoá ảnh thành công');

  @override
  Future<ApiResponse<void>> setCoverImage(
    String roomId,
    String imageId,
  ) async =>
      setCoverImageResult ??
      ApiResponse(success: true, message: 'Đặt ảnh cover thành công');

  @override
  Future<ApiResponse<Map<String, dynamic>>> upsertPrice(
    String roomId,
    Map<String, dynamic> data,
  ) async =>
      upsertPriceResult ??
      ApiResponse(
        success: true,
        data: {'weekdayPrice': 500000},
        message: 'Cập nhật giá thành công',
      );
}

// ─── Fake: dashboard + report (prevent post-invalidation re-fetch errors) ──────

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

// ─── Test helpers ─────────────────────────────────────────────────────────────

RoomModel _fakeRoom(String id) => RoomModel(
      id: id,
      homestayId: 'homestay-1',
      name: 'Phòng $id',
      code: 'P-$id',
    );

ProviderContainer _makeContainer(FakeRoomRepository repo) {
  return ProviderContainer(
    overrides: [
      roomRepositoryProvider.overrideWithValue(repo),
      dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
      reportRepositoryProvider.overrideWithValue(_FakeReportRepository()),
    ],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── roomListProvider ────────────────────────────────────────────────────────
  group('roomListProvider', () {
    test('returns list of rooms on success', () async {
      final repo = FakeRoomRepository()
        ..getRoomsResult = ApiResponse(
          success: true,
          data: [_fakeRoom('r1'), _fakeRoom('r2')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(roomListProvider(null).future);

      expect(result, hasLength(2));
      expect(result.first.id, 'r1');
    });

    test('scopes by homestayId param', () async {
      final repo = FakeRoomRepository()
        ..getRoomsResult = ApiResponse(
          success: true,
          data: [_fakeRoom('r-scoped')],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(
        roomListProvider('homestay-X').future,
      );

      expect(result.single.id, 'r-scoped');
    });

    test('throws when success is false', () async {
      final repo = FakeRoomRepository()
        ..getRoomsResult = ApiResponse(
          success: false,
          message: 'Không có quyền',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(roomListProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeRoomRepository()
        ..getRoomsResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(roomListProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── roomDetailProvider ──────────────────────────────────────────────────────
  group('roomDetailProvider', () {
    test('returns room on success', () async {
      final repo = FakeRoomRepository()
        ..getRoomDetailResult = ApiResponse(
          success: true,
          data: _fakeRoom('detail-1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(roomDetailProvider('detail-1').future);

      expect(result.id, 'detail-1');
      expect(result.homestayId, 'homestay-1');
    });

    test('throws when success is false', () async {
      final repo = FakeRoomRepository()
        ..getRoomDetailResult = ApiResponse(
          success: false,
          message: 'Phòng không tồn tại',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(roomDetailProvider('missing').future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when data is null on success', () async {
      final repo = FakeRoomRepository()
        ..getRoomDetailResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(roomDetailProvider('any').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── RoomActionsNotifier.create ──────────────────────────────────────────────
  group('RoomActionsNotifier.create', () {
    test('initial state is AsyncData(null)', () {
      final container = _makeContainer(FakeRoomRepository());
      addTearDown(container.dispose);

      expect(container.read(roomActionsProvider), isA<AsyncData<void>>());
    });

    test('returns RoomModel and state is AsyncData on success', () async {
      final repo = FakeRoomRepository()
        ..createRoomResult = ApiResponse(
          success: true,
          data: _fakeRoom('created-1'),
          message: 'Tạo phòng thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .create({'name': 'Phòng mới', 'code': 'P-01'});

      expect(result, isNotNull);
      expect(result!.id, 'created-1');
      expect(container.read(roomActionsProvider), isA<AsyncData<void>>());
    });

    test('returns null and state is AsyncError on failure', () async {
      final repo = FakeRoomRepository()
        ..createRoomResult = ApiResponse(
          success: false,
          message: 'Mã phòng đã tồn tại',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .create({'name': 'Phòng', 'code': 'P-DUP'});

      expect(result, isNull);
      final state = container.read(roomActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Mã phòng đã tồn tại'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeRoomRepository()
        ..createRoomResult = ApiResponse(
          success: true,
          data: _fakeRoom('c1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        roomActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(roomActionsProvider.notifier).create({});

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeRoomRepository()
        ..createRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi server',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        roomActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(roomActionsProvider.notifier).create({});

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });
  });

  // ── RoomActionsNotifier.update ──────────────────────────────────────────────
  group('RoomActionsNotifier.update', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeRoomRepository()
        ..updateRoomResult = ApiResponse(
          success: true,
          data: _fakeRoom('r-upd'),
          message: 'Cập nhật thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .update('r-upd', {'name': 'Tên mới'});

      expect(result, isTrue);
      expect(container.read(roomActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeRoomRepository()
        ..updateRoomResult = ApiResponse(
          success: false,
          message: 'Không có quyền sửa phòng',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .update('r-no-perm', {});

      expect(result, isFalse);
      final state = container.read(roomActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Không có quyền sửa phòng'),
      );
    });

    test('state transitions loading → data on success', () async {
      final repo = FakeRoomRepository()
        ..updateRoomResult = ApiResponse(
          success: true,
          data: _fakeRoom('u1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        roomActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(roomActionsProvider.notifier)
          .update('u1', {'bedrooms': 2});

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });
  });

  // ── RoomActionsNotifier.delete ──────────────────────────────────────────────
  group('RoomActionsNotifier.delete', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeRoomRepository()
        ..deleteRoomResult = ApiResponse(
          success: true,
          message: 'Xoá phòng thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .delete('r-del');

      expect(result, isTrue);
      expect(container.read(roomActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeRoomRepository()
        ..deleteRoomResult = ApiResponse(
          success: false,
          message: 'Phòng đang có khách ở',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .delete('r-occupied');

      expect(result, isFalse);
      final state = container.read(roomActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Phòng đang có khách ở'),
      );
    });

    test('state transitions loading → error on failure', () async {
      final repo = FakeRoomRepository()
        ..deleteRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        roomActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(roomActionsProvider.notifier).delete('x');

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });
  });

  // ── RoomActionsNotifier.uploadImages ────────────────────────────────────────
  group('RoomActionsNotifier.uploadImages', () {
    test('returns (true, empty string) on success', () async {
      final repo = FakeRoomRepository()
        ..uploadImagesResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final (ok, msg) = await container
          .read(roomActionsProvider.notifier)
          .uploadImages('r1', ['/path/to/img.jpg']);

      expect(ok, isTrue);
      expect(msg, isEmpty);
    });

    test('returns (false, error message) on failure', () async {
      final repo = FakeRoomRepository()
        ..uploadImagesResult = ApiResponse(
          success: false,
          message: 'File quá lớn',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final (ok, msg) = await container
          .read(roomActionsProvider.notifier)
          .uploadImages('r1', ['/path/big.jpg']);

      expect(ok, isFalse);
      expect(msg, 'File quá lớn');
    });

    test('does not change notifier state (no loading transition)', () async {
      final repo = FakeRoomRepository()
        ..uploadImagesResult = ApiResponse(
          success: true,
          data: [],
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        roomActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(roomActionsProvider.notifier)
          .uploadImages('r1', []);

      // uploadImages does not set state = loading, so no state emissions
      expect(states, isEmpty);
    });
  });

  // ── RoomActionsNotifier.deleteImage ─────────────────────────────────────────
  group('RoomActionsNotifier.deleteImage', () {
    test('returns true on success', () async {
      final repo = FakeRoomRepository()
        ..deleteImageResult = ApiResponse(
          success: true,
          message: 'Xoá ảnh thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .deleteImage('r1', 'img-1');

      expect(result, isTrue);
    });

    test('returns false on failure', () async {
      final repo = FakeRoomRepository()
        ..deleteImageResult = ApiResponse(
          success: false,
          message: 'Ảnh không tồn tại',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .deleteImage('r1', 'img-missing');

      expect(result, isFalse);
    });
  });

  // ── RoomActionsNotifier.setCoverImage ────────────────────────────────────────
  group('RoomActionsNotifier.setCoverImage', () {
    test('returns true on success', () async {
      final repo = FakeRoomRepository()
        ..setCoverImageResult = ApiResponse(
          success: true,
          message: 'Đặt ảnh cover thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .setCoverImage('r1', 'img-cover');

      expect(result, isTrue);
    });

    test('returns false on failure', () async {
      final repo = FakeRoomRepository()
        ..setCoverImageResult = ApiResponse(
          success: false,
          message: 'Lỗi khi đặt cover',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .setCoverImage('r1', 'img-bad');

      expect(result, isFalse);
    });
  });

  // ── RoomActionsNotifier.upsertPrice ──────────────────────────────────────────
  group('RoomActionsNotifier.upsertPrice', () {
    test('returns true on success', () async {
      final repo = FakeRoomRepository()
        ..upsertPriceResult = ApiResponse(
          success: true,
          data: {'weekdayPrice': 600000},
          message: 'Cập nhật giá thành công',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .upsertPrice('r1', {'weekdayPrice': 600000});

      expect(result, isTrue);
    });

    test('returns false on failure', () async {
      final repo = FakeRoomRepository()
        ..upsertPriceResult = ApiResponse(
          success: false,
          message: 'Giá không hợp lệ',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(roomActionsProvider.notifier)
          .upsertPrice('r1', {'weekdayPrice': -1});

      expect(result, isFalse);
    });

    test('does not change notifier state on success', () async {
      final repo = FakeRoomRepository()
        ..upsertPriceResult = ApiResponse(
          success: true,
          data: {'weekdayPrice': 500000},
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      // upsertPrice does not set loading state on the notifier
      final states = <AsyncValue<void>>[];
      container.listen(
        roomActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(roomActionsProvider.notifier)
          .upsertPrice('r1', {});

      expect(states, isEmpty);
    });
  });

  // ── Sequential operations ───────────────────────────────────────────────────
  group('RoomActionsNotifier sequential operations', () {
    test('state resets to AsyncData after two consecutive successes', () async {
      final repo = FakeRoomRepository()
        ..createRoomResult = ApiResponse(
          success: true,
          data: _fakeRoom('seq-1'),
          message: '',
        )
        ..updateRoomResult = ApiResponse(
          success: true,
          data: _fakeRoom('seq-1'),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(roomActionsProvider.notifier);

      await notifier.create({});
      expect(container.read(roomActionsProvider), isA<AsyncData<void>>());

      await notifier.update('seq-1', {});
      expect(container.read(roomActionsProvider), isA<AsyncData<void>>());
    });

    test('after error, next success resets state to AsyncData', () async {
      final repo = FakeRoomRepository()
        ..deleteRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi xoá',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(roomActionsProvider.notifier);

      await notifier.delete('r-fail');
      expect(container.read(roomActionsProvider), isA<AsyncError<void>>());

      repo.deleteRoomResult = ApiResponse(
        success: true,
        message: 'Xoá thành công',
      );
      await notifier.delete('r-ok');
      expect(container.read(roomActionsProvider), isA<AsyncData<void>>());
    });
  });
}
