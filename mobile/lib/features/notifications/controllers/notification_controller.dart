import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository());

final notificationListProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotifications();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repo;
  final Ref _ref;

  NotificationActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    _ref.invalidate(notificationListProvider);
    _ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    _ref.invalidate(notificationListProvider);
    _ref.invalidate(unreadCountProvider);
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, AsyncValue<void>>(
        (ref) {
  final repo = ref.read(notificationRepositoryProvider);
  return NotificationActionsNotifier(repo, ref);
});
