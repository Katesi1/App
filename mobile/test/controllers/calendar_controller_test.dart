import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/models/calendar_model.dart';
import 'package:mobile/data/repositories/calendar_repository.dart';
import 'package:mobile/features/calendar/controllers/calendar_controller.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class FakeCalendarRepository extends CalendarRepository {
  ApiResponse<CalendarGrid>? getGridResult;
  ApiResponse<CalendarGrid>? getPublicGridResult;
  ApiResponse<Map<String, dynamic>>? lockRoomResult;
  ApiResponse<Map<String, dynamic>>? markAsSoldResult;
  ApiResponse<void>? unlockRoomResult;
  ApiResponse<AdminContact>? getAdminContactResult;

  // Track last params passed to verify routing (isPublic → correct method)
  String? lastGetGridStart;
  String? lastGetPublicGridStart;
  String? lastLockPropertyId;
  String? lastUnlockPropertyId;
  String? lastMarkAsSoldPropertyId;

  @override
  Future<ApiResponse<CalendarGrid>> getGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async {
    lastGetGridStart = startDate;
    return getGridResult ??
        ApiResponse(
          success: true,
          data: const CalendarGrid(),
          message: '',
        );
  }

  @override
  Future<ApiResponse<CalendarGrid>> getPublicGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async {
    lastGetPublicGridStart = startDate;
    return getPublicGridResult ??
        ApiResponse(
          success: true,
          data: const CalendarGrid(),
          message: '',
        );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> lockRoom({
    required String propertyId,
    required String date,
    int status = 0,
  }) async {
    lastLockPropertyId = propertyId;
    return lockRoomResult ??
        ApiResponse(
          success: true,
          data: {},
          message: 'Đã khoá phòng',
        );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> markAsSold({
    required String propertyId,
    required String date,
  }) async {
    lastMarkAsSoldPropertyId = propertyId;
    return markAsSoldResult ??
        ApiResponse(
          success: true,
          data: {},
          message: 'Đã đánh dấu đã bán',
        );
  }

  @override
  Future<ApiResponse<void>> unlockRoom({
    required String propertyId,
    required String date,
  }) async {
    lastUnlockPropertyId = propertyId;
    return unlockRoomResult ??
        ApiResponse(success: true, message: 'Đã mở khoá phòng');
  }

  @override
  Future<ApiResponse<AdminContact>> getAdminContact() async =>
      getAdminContactResult ??
      ApiResponse(
        success: true,
        data: const AdminContact(name: 'Admin', phone: '0123456789'),
        message: '',
      );
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

const _kParams = CalendarGridParams(
  startDate: '2025-01-01',
  endDate: '2025-01-31',
);

const _kPublicParams = CalendarGridParams(
  startDate: '2025-02-01',
  endDate: '2025-02-28',
  isPublic: true,
);

CalendarGrid _fakeGrid({int roomCount = 2}) => CalendarGrid(
      properties: List.generate(
        roomCount,
        (i) => CalendarRoomRow(
          id: 'room-$i',
          code: 'R$i',
          name: 'Phòng $i',
        ),
      ),
    );

ProviderContainer _makeContainer(FakeCalendarRepository repo) {
  return ProviderContainer(
    overrides: [
      calendarRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── CalendarGridParams equality & hashCode ──────────────────────────────────
  group('CalendarGridParams', () {
    test('equal when all fields match', () {
      const a = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        propertyId: 'p1',
        type: 1,
        isPublic: false,
      );
      const b = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        propertyId: 'p1',
        type: 1,
        isPublic: false,
      );

      expect(a, equals(b));
    });

    test('not equal when startDate differs', () {
      const a = CalendarGridParams(startDate: '2025-01-01', endDate: '2025-01-31');
      const b = CalendarGridParams(startDate: '2025-02-01', endDate: '2025-01-31');

      expect(a, isNot(equals(b)));
    });

    test('not equal when endDate differs', () {
      const a = CalendarGridParams(startDate: '2025-01-01', endDate: '2025-01-31');
      const b = CalendarGridParams(startDate: '2025-01-01', endDate: '2025-02-28');

      expect(a, isNot(equals(b)));
    });

    test('not equal when propertyId differs', () {
      const a = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        propertyId: 'p1',
      );
      const b = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        propertyId: 'p2',
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when type differs', () {
      const a = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        type: 0,
      );
      const b = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        type: 1,
      );

      expect(a, isNot(equals(b)));
    });

    test('not equal when isPublic differs', () {
      const a = CalendarGridParams(startDate: '2025-01-01', endDate: '2025-01-31');
      const b = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        isPublic: true,
      );

      expect(a, isNot(equals(b)));
    });

    test('hashCode is equal when params are equal', () {
      const a = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        propertyId: 'p1',
        type: 2,
        isPublic: true,
      );
      const b = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        propertyId: 'p1',
        type: 2,
        isPublic: true,
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs when params differ', () {
      const a = CalendarGridParams(startDate: '2025-01-01', endDate: '2025-01-31');
      const b = CalendarGridParams(startDate: '2025-02-01', endDate: '2025-02-28');

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('isPublic defaults to false', () {
      const params = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
      );

      expect(params.isPublic, isFalse);
    });

    test('isPublic can be set to true', () {
      const params = CalendarGridParams(
        startDate: '2025-01-01',
        endDate: '2025-01-31',
        isPublic: true,
      );

      expect(params.isPublic, isTrue);
    });
  });

  // ── calendarGridProvider — private grid (isPublic = false) ──────────────────
  group('calendarGridProvider (isPublic=false)', () {
    test('returns CalendarGrid on success', () async {
      final repo = FakeCalendarRepository()
        ..getGridResult = ApiResponse(
          success: true,
          data: _fakeGrid(roomCount: 3),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(calendarGridProvider(_kParams).future);

      expect(result.properties, hasLength(3));
      expect(result.properties.first.id, 'room-0');
    });

    test('throws Exception when success is false', () async {
      final repo = FakeCalendarRepository()
        ..getGridResult = ApiResponse(
          success: false,
          message: 'Không có quyền xem lịch',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(calendarGridProvider(_kParams).future),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Không có quyền xem lịch'),
          ),
        ),
      );
    });

    test('throws Exception when data is null on success', () async {
      final repo = FakeCalendarRepository()
        ..getGridResult = ApiResponse(
          success: true,
          data: null,
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(calendarGridProvider(_kParams).future),
        throwsA(isA<Exception>()),
      );
    });

    test('calls getGrid (not getPublicGrid) when isPublic=false', () async {
      final repo = FakeCalendarRepository();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(calendarGridProvider(_kParams).future);

      expect(repo.lastGetGridStart, '2025-01-01');
      expect(repo.lastGetPublicGridStart, isNull);
    });

    test('returns empty properties list when grid has no rooms', () async {
      final repo = FakeCalendarRepository()
        ..getGridResult = ApiResponse(
          success: true,
          data: const CalendarGrid(),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(calendarGridProvider(_kParams).future);

      expect(result.properties, isEmpty);
    });
  });

  // ── calendarGridProvider — public grid (isPublic = true) ────────────────────
  group('calendarGridProvider (isPublic=true)', () {
    test('returns CalendarGrid on success', () async {
      final repo = FakeCalendarRepository()
        ..getPublicGridResult = ApiResponse(
          success: true,
          data: _fakeGrid(roomCount: 1),
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result =
          await container.read(calendarGridProvider(_kPublicParams).future);

      expect(result.properties, hasLength(1));
    });

    test('throws Exception when success is false', () async {
      final repo = FakeCalendarRepository()
        ..getPublicGridResult = ApiResponse(
          success: false,
          message: 'Lịch công khai không khả dụng',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(calendarGridProvider(_kPublicParams).future),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Lịch công khai không khả dụng'),
          ),
        ),
      );
    });

    test('calls getPublicGrid (not getGrid) when isPublic=true', () async {
      final repo = FakeCalendarRepository();
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(calendarGridProvider(_kPublicParams).future);

      expect(repo.lastGetPublicGridStart, '2025-02-01');
      expect(repo.lastGetGridStart, isNull);
    });
  });

  // ── CalendarActionsNotifier initial state ────────────────────────────────────
  group('CalendarActionsNotifier initial state', () {
    test('initial state is AsyncData(null)', () {
      final container = _makeContainer(FakeCalendarRepository());
      addTearDown(container.dispose);

      final state = container.read(calendarActionsProvider);

      expect(state, isA<AsyncData<void>>());
    });
  });

  // ── CalendarActionsNotifier.lockRoom ─────────────────────────────────────────
  group('CalendarActionsNotifier.lockRoom', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(
          success: true,
          data: {'propertyId': 'p1', 'date': '2025-01-15'},
          message: 'Đã khoá phòng',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(calendarActionsProvider.notifier).lockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(result, isTrue);
      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(
          success: false,
          message: 'Phòng đã được khoá',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(calendarActionsProvider.notifier).lockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(result, isFalse);
      final state = container.read(calendarActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Phòng đã được khoá'),
      );
    });

    test('state transitions loading → AsyncData on success', () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(
          success: true,
          data: {},
          message: '',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        calendarActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(calendarActionsProvider.notifier).lockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → AsyncError on failure', () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi khoá phòng',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        calendarActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(calendarActionsProvider.notifier).lockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });

    test('uses custom status parameter when provided', () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(success: true, data: {}, message: '');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      // Should not throw — verifies the status param is passed through
      final result = await container.read(calendarActionsProvider.notifier).lockRoom(
            propertyId: 'p2',
            date: '2025-01-20',
            gridParams: _kParams,
            status: 2, // BOOKED
          );

      expect(result, isTrue);
      expect(repo.lastLockPropertyId, 'p2');
    });
  });

  // ── CalendarActionsNotifier.unlockRoom ───────────────────────────────────────
  group('CalendarActionsNotifier.unlockRoom', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeCalendarRepository()
        ..unlockRoomResult = ApiResponse(success: true, message: 'Đã mở khoá');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(calendarActionsProvider.notifier)
          .unlockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(result, isTrue);
      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeCalendarRepository()
        ..unlockRoomResult = ApiResponse(
          success: false,
          message: 'Phòng không ở trạng thái khoá',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(calendarActionsProvider.notifier)
          .unlockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(result, isFalse);
      final state = container.read(calendarActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Phòng không ở trạng thái khoá'),
      );
    });

    test('state transitions loading → AsyncData on success', () async {
      final repo = FakeCalendarRepository()
        ..unlockRoomResult = ApiResponse(success: true, message: '');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        calendarActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(calendarActionsProvider.notifier).unlockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → AsyncError on failure', () async {
      final repo = FakeCalendarRepository()
        ..unlockRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi mở khoá',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        calendarActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(calendarActionsProvider.notifier).unlockRoom(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });

    test('passes correct propertyId to repository', () async {
      final repo = FakeCalendarRepository()
        ..unlockRoomResult = ApiResponse(success: true, message: '');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(calendarActionsProvider.notifier).unlockRoom(
            propertyId: 'target-property',
            date: '2025-03-10',
            gridParams: _kParams,
          );

      expect(repo.lastUnlockPropertyId, 'target-property');
    });
  });

  // ── CalendarActionsNotifier.markAsSold ──────────────────────────────────────
  group('CalendarActionsNotifier.markAsSold', () {
    test('returns true and state is AsyncData on success', () async {
      final repo = FakeCalendarRepository()
        ..markAsSoldResult = ApiResponse(
          success: true,
          data: {},
          message: 'Đã đánh dấu đã bán',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(calendarActionsProvider.notifier)
          .markAsSold(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(result, isTrue);
      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is AsyncError on failure', () async {
      final repo = FakeCalendarRepository()
        ..markAsSoldResult = ApiResponse(
          success: false,
          message: 'Không thể đánh dấu đã bán',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container
          .read(calendarActionsProvider.notifier)
          .markAsSold(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(result, isFalse);
      final state = container.read(calendarActionsProvider);
      expect(state, isA<AsyncError<void>>());
      expect(
        (state as AsyncError).error.toString(),
        contains('Không thể đánh dấu đã bán'),
      );
    });

    test('state transitions loading → AsyncData on success', () async {
      final repo = FakeCalendarRepository()
        ..markAsSoldResult = ApiResponse(success: true, data: {}, message: '');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        calendarActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(calendarActionsProvider.notifier).markAsSold(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(states, hasLength(2));
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
    });

    test('state transitions loading → AsyncError on failure', () async {
      final repo = FakeCalendarRepository()
        ..markAsSoldResult = ApiResponse(
          success: false,
          message: 'Lỗi đánh dấu bán',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final states = <AsyncValue<void>>[];
      container.listen(
        calendarActionsProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(calendarActionsProvider.notifier).markAsSold(
            propertyId: 'p1',
            date: '2025-01-15',
            gridParams: _kParams,
          );

      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncError<void>>());
    });

    test('passes correct propertyId to repository', () async {
      final repo = FakeCalendarRepository()
        ..markAsSoldResult = ApiResponse(success: true, data: {}, message: '');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(calendarActionsProvider.notifier).markAsSold(
            propertyId: 'sold-property',
            date: '2025-04-05',
            gridParams: _kParams,
          );

      expect(repo.lastMarkAsSoldPropertyId, 'sold-property');
    });
  });

  // ── State reset after error ──────────────────────────────────────────────────
  group('CalendarActionsNotifier state reset', () {
    test('after lockRoom error, next lockRoom success resets to AsyncData',
        () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi lần đầu',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(calendarActionsProvider.notifier);

      await notifier.lockRoom(
        propertyId: 'p1',
        date: '2025-01-15',
        gridParams: _kParams,
      );
      expect(container.read(calendarActionsProvider), isA<AsyncError<void>>());

      repo.lockRoomResult = ApiResponse(success: true, data: {}, message: '');
      await notifier.lockRoom(
        propertyId: 'p1',
        date: '2025-01-16',
        gridParams: _kParams,
      );

      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });

    test('after unlockRoom error, next unlockRoom success resets to AsyncData',
        () async {
      final repo = FakeCalendarRepository()
        ..unlockRoomResult = ApiResponse(
          success: false,
          message: 'Lỗi mở khoá',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(calendarActionsProvider.notifier);

      await notifier.unlockRoom(
        propertyId: 'p1',
        date: '2025-01-15',
        gridParams: _kParams,
      );
      expect(container.read(calendarActionsProvider), isA<AsyncError<void>>());

      repo.unlockRoomResult = ApiResponse(success: true, message: '');
      await notifier.unlockRoom(
        propertyId: 'p1',
        date: '2025-01-15',
        gridParams: _kParams,
      );

      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });

    test('after markAsSold error, next markAsSold success resets to AsyncData',
        () async {
      final repo = FakeCalendarRepository()
        ..markAsSoldResult = ApiResponse(
          success: false,
          message: 'Lỗi đánh dấu',
        );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(calendarActionsProvider.notifier);

      await notifier.markAsSold(
        propertyId: 'p1',
        date: '2025-01-15',
        gridParams: _kParams,
      );
      expect(container.read(calendarActionsProvider), isA<AsyncError<void>>());

      repo.markAsSoldResult = ApiResponse(success: true, data: {}, message: '');
      await notifier.markAsSold(
        propertyId: 'p1',
        date: '2025-01-16',
        gridParams: _kParams,
      );

      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });

    test('cross-action recovery: error from lockRoom, then success via unlockRoom',
        () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(
          success: false,
          message: 'Khoá thất bại',
        )
        ..unlockRoomResult = ApiResponse(success: true, message: 'Mở thành công');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(calendarActionsProvider.notifier);

      await notifier.lockRoom(
        propertyId: 'p1',
        date: '2025-01-15',
        gridParams: _kParams,
      );
      expect(container.read(calendarActionsProvider), isA<AsyncError<void>>());

      await notifier.unlockRoom(
        propertyId: 'p1',
        date: '2025-01-15',
        gridParams: _kParams,
      );
      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });

    test('two consecutive successes both leave state as AsyncData', () async {
      final repo = FakeCalendarRepository()
        ..lockRoomResult = ApiResponse(success: true, data: {}, message: '')
        ..markAsSoldResult = ApiResponse(success: true, data: {}, message: '');
      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(calendarActionsProvider.notifier);

      await notifier.lockRoom(
        propertyId: 'p1',
        date: '2025-01-10',
        gridParams: _kParams,
      );
      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());

      await notifier.markAsSold(
        propertyId: 'p1',
        date: '2025-01-11',
        gridParams: _kParams,
      );
      expect(container.read(calendarActionsProvider), isA<AsyncData<void>>());
    });
  });
}
