import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/chat_socket_service.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../auth/controllers/auth_controller.dart';

// ── Infra providers ─────────────────────────────────────────────────────────

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository());

final chatSocketServiceProvider =
    Provider<ChatSocketService>((ref) => ChatSocketService.instance);

// ── Inbox (danh sách hội thoại, realtime) ────────────────────────────────────

/// Notifier inbox: load REST page 1 + cập nhật realtime qua socket
/// (`message:new` → bump preview/unread + đẩy lên đầu).
class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<ConversationModel>>> {
  ConversationsNotifier(this._repo, this._socket, this._currentUserId)
      : super(const AsyncValue.loading()) {
    _sub = _socket.onMessageNew.listen(_onIncoming);
    _readSub = _socket.onReadUpdate.listen(_onRead);
    load();
  }

  final ChatRepository _repo;
  final ChatSocketService _socket;
  final String? _currentUserId;
  StreamSubscription<SocketMessageEvent>? _sub;
  StreamSubscription<SocketReadEvent>? _readSub;

  Future<void> load() async {
    final result = await _repo.getConversations();
    if (!mounted) return;
    if (result.success) {
      state = AsyncValue.data(result.data ?? const []);
    } else {
      state = AsyncValue.error(result.message, StackTrace.current);
    }
  }

  Future<void> refresh() => load();

  void _onIncoming(SocketMessageEvent event) {
    final current = state.valueOrNull;
    if (current == null) return;
    final idx = current.indexWhere((c) => c.id == event.conversationId);
    if (idx < 0) {
      // Conversation chưa có trong list (vd booking mới) → refetch.
      unawaited(load());
      return;
    }
    final isMine = event.message.senderId == _currentUserId;
    final conv = current[idx].copyWith(
      lastMessageAt: event.message.createdAt,
      lastMessagePreview: event.message.content,
      lastSenderId: event.message.senderId,
      myUnread: isMine ? current[idx].myUnread : current[idx].myUnread + 1,
    );
    final updated = [...current]..removeAt(idx);
    updated.insert(0, conv);
    state = AsyncValue.data(updated);
  }

  void _onRead(SocketReadEvent event) {
    // Mình đọc ở thiết bị khác → zero unread của conversation đó.
    if (event.userId != _currentUserId) return;
    _zeroUnread(event.conversationId);
  }

  /// Gọi khi user mở 1 conversation — zero unread local ngay (UX), socket/REST
  /// markRead chạy song song ở thread controller.
  void markReadLocally(String conversationId) => _zeroUnread(conversationId);

  void _zeroUnread(String conversationId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final idx = current.indexWhere((c) => c.id == conversationId);
    if (idx < 0 || current[idx].myUnread == 0) return;
    final updated = [...current];
    updated[idx] = updated[idx].copyWith(myUnread: 0);
    state = AsyncValue.data(updated);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _readSub?.cancel();
    super.dispose();
  }
}

final conversationsProvider = StateNotifierProvider<ConversationsNotifier,
    AsyncValue<List<ConversationModel>>>((ref) {
  // watch (không read) currentUserId → logout/đổi tài khoản trong cùng phiên
  // app sẽ rebuild notifier với đúng userId (tránh filter event sai user).
  return ConversationsNotifier(
    ref.read(chatRepositoryProvider),
    ref.read(chatSocketServiceProvider),
    ref.watch(currentUserProvider.select((u) => u?.id)),
  );
});

// ── Unread badge tổng (cho icon AppBar) ──────────────────────────────────────

/// Badge tổng tin chưa đọc. Fetch REST + refresh khi có tin mới (không phải
/// của mình) hoặc khi user đọc xong 1 hội thoại.
class ChatUnreadNotifier extends StateNotifier<int> {
  ChatUnreadNotifier(this._repo, this._socket, this._currentUserId) : super(0) {
    _sub = _socket.onMessageNew.listen((e) {
      if (e.message.senderId != _currentUserId) unawaited(refresh());
    });
    _readSub = _socket.onReadUpdate.listen((e) {
      if (e.userId == _currentUserId) unawaited(refresh());
    });
    refresh();
  }

  final ChatRepository _repo;
  final ChatSocketService _socket;
  final String? _currentUserId;
  StreamSubscription<SocketMessageEvent>? _sub;
  StreamSubscription<SocketReadEvent>? _readSub;

  Future<void> refresh() async {
    final result = await _repo.getUnreadCount();
    if (!mounted) return;
    if (result.success) state = result.data ?? 0;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _readSub?.cancel();
    super.dispose();
  }
}

final chatUnreadProvider =
    StateNotifierProvider<ChatUnreadNotifier, int>((ref) {
  return ChatUnreadNotifier(
    ref.read(chatRepositoryProvider),
    ref.read(chatSocketServiceProvider),
    ref.watch(currentUserProvider.select((u) => u?.id)),
  );
});

// ── Actions (tạo/mở conversation) ────────────────────────────────────────────

class ChatActionsNotifier extends StateNotifier<AsyncValue<void>> {
  ChatActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ChatRepository _repo;
  final Ref _ref;

  /// Mở (hoặc tạo idempotent) conversation cho 1 booking. Trả về conversationId
  /// để điều hướng, hoặc null nếu lỗi (message ở [AsyncValue.error]).
  Future<String?> openBookingConversation(String bookingId) async {
    state = const AsyncValue.loading();
    final result = await _repo.createConversation(
      type: ConversationType.booking,
      bookingId: bookingId,
    );
    if (result.success && result.data != null) {
      state = const AsyncValue.data(null);
      // Inbox có thể chưa chứa conversation mới → refresh.
      unawaited(_ref.read(conversationsProvider.notifier).refresh());
      return result.data!.id;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return null;
  }
}

final chatActionsProvider =
    StateNotifierProvider<ChatActionsNotifier, AsyncValue<void>>((ref) {
  return ChatActionsNotifier(ref.read(chatRepositoryProvider), ref);
});
