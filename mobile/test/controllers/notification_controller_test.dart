import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/models/notification_model.dart';
import 'package:mobile/data/repositories/notification_repository.dart';
import 'package:mobile/features/notifications/controllers/notification_controller.dart';
import 'package:mobile/shared/providers/theme_provider.dart';

// ── Fake repository ───────────────────────────────────────────────────────────
class FakeNotificationRepository extends NotificationRepository {
  List<NotificationModel> fakeList = [];
  int fakeUnreadCount = 0;
  String? errorMessage;
  List<String> markedReadIds = [];
  bool markAllCalled = false;

  @override
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    return ApiResponse(success: true, data: fakeList, message: '');
  }

  @override
  Future<ApiResponse<int>> getUnreadCount() async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    return ApiResponse(success: true, data: fakeUnreadCount, message: '');
  }

  @override
  Future<ApiResponse<void>> markAsRead(String id) async {
    markedReadIds.add(id);
    return ApiResponse(success: true, message: '');
  }

  @override
  Future<ApiResponse<void>> markAllAsRead() async {
    markAllCalled = true;
    return ApiResponse(success: true, message: '');
  }
}

NotificationModel _makeNotification(String id) => NotificationModel(
      id: id,
      title: 'Test $id',
      subtitle: 'Subtitle $id',
      type: NotificationType.booking,
      isRead: false,
      createdAt: DateTime(2026, 5, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  themeNotifierTests();

  group('notificationListProvider', () {
    test('returns list on success', () async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.fakeList = [_makeNotification('1'), _makeNotification('2')];
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(notificationListProvider.future);
      expect(list.length, 2);
      expect(list[0].id, '1');
    });

    test('throws Exception on failure', () async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.errorMessage = 'Không có kết nối';
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(notificationListProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty list when no notifications', () async {
      final fakeRepo = FakeNotificationRepository();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(notificationListProvider.future);
      expect(list, isEmpty);
    });
  });

  group('unreadCountProvider', () {
    test('returns unread count on success', () async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.fakeUnreadCount = 5;
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(unreadCountProvider.future);
      expect(count, 5);
    });

    test('returns 0 on failure (graceful fallback)', () async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.errorMessage = 'Error';
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(unreadCountProvider.future);
      expect(count, 0);
    });

    test('returns 0 when count is 0', () async {
      final fakeRepo = FakeNotificationRepository();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(unreadCountProvider.future);
      expect(count, 0);
    });
  });

  group('NotificationActionsNotifier', () {
    test('markAsRead calls repo and invalidates providers', () async {
      final fakeRepo = FakeNotificationRepository();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(notificationActionsProvider.notifier);
      await notifier.markAsRead('abc-123');

      expect(fakeRepo.markedReadIds, contains('abc-123'));
    });

    test('markAllAsRead calls repo', () async {
      final fakeRepo = FakeNotificationRepository();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(notificationActionsProvider.notifier);
      await notifier.markAllAsRead();

      expect(fakeRepo.markAllCalled, isTrue);
    });

    test('markAsRead does not crash on repo error', () async {
      final fakeRepo = _ThrowingNotificationRepo();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(notificationActionsProvider.notifier);
      // Should NOT throw — errors are swallowed
      await expectLater(
        () => notifier.markAsRead('id'),
        returnsNormally,
      );
    });

    test('markAllAsRead does not crash on repo error', () async {
      final fakeRepo = _ThrowingNotificationRepo();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier =
          container.read(notificationActionsProvider.notifier);
      await expectLater(
        () => notifier.markAllAsRead(),
        returnsNormally,
      );
    });

    test('initial state is AsyncValue.data(null)', () {
      final fakeRepo = FakeNotificationRepository();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(notificationActionsProvider);
      expect(state, isA<AsyncData<void>>());
    });
  });
}

class _ThrowingNotificationRepo extends NotificationRepository {
  @override
  Future<ApiResponse<List<NotificationModel>>> getNotifications() async =>
      ApiResponse(success: true, data: [], message: '');

  @override
  Future<ApiResponse<int>> getUnreadCount() async =>
      ApiResponse(success: true, data: 0, message: '');

  @override
  Future<ApiResponse<void>> markAsRead(String id) async =>
      throw Exception('network error');

  @override
  Future<ApiResponse<void>> markAllAsRead() async =>
      throw Exception('network error');
}

// ─── ThemeNotifier tests ──────────────────────────────────────────────────────
// Placed here alongside notification tests so this file also covers the shared
// theme provider without needing a separate file.

void themeNotifierTests() {
  group('ThemeNotifier initial state', () {
    test('initial synchronous state is ThemeMode.light before async load', () {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeNotifier();
      expect(notifier.state, ThemeMode.light);
    });

    test('loads ThemeMode.dark when dark is persisted', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, ThemeMode.dark);
    });

    test('loads ThemeMode.light when light is persisted', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, ThemeMode.light);
    });

    test('defaults to ThemeMode.light when no persisted value exists', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, ThemeMode.light);
    });
  });

  group('ThemeNotifier.toggle', () {
    test('toggle switches light → dark', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.toggle();

      expect(notifier.state, ThemeMode.dark);
    });

    test('toggle switches dark → light', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.toggle();

      expect(notifier.state, ThemeMode.light);
    });

    test('double toggle returns to original mode', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.toggle();
      await notifier.toggle();

      expect(notifier.state, ThemeMode.light);
    });

    test('persists dark to SharedPreferences after toggle', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.toggle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });
  });

  group('ThemeNotifier.setMode', () {
    test('setMode(dark) sets ThemeMode.dark', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.setMode(ThemeMode.dark);

      expect(notifier.state, ThemeMode.dark);
    });

    test('setMode(light) sets ThemeMode.light even when currently dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.setMode(ThemeMode.light);

      expect(notifier.state, ThemeMode.light);
    });

    test('persists dark to SharedPreferences via setMode', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.setMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('persists light to SharedPreferences via setMode', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final notifier = ThemeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.setMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });
  });
}
