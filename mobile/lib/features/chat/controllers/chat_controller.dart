import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../services/chat_socket_service.dart';

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository());

/// Socket chat — connect khi có user (login), tự huỷ khi logout. Watch theo
/// `user.id` để không reconnect mỗi lần profile đổi field (KYC/sub...).
final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final userId = ref.watch(currentUserProvider.select((u) => u?.id));
  final service = ChatSocketService();
  if (userId != null) service.connect();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream sự kiện realtime — screen/notifier `ref.listen` để cập nhật UI.
final chatSocketEventsProvider = StreamProvider<ChatSocketEvent>((ref) {
  return ref.watch(chatSocketServiceProvider).events;
});

/// Badge tổng tin chưa đọc cho icon chat ở Dashboard.
final chatUnreadCountProvider =
    StateNotifierProvider<ChatUnreadNotifier, int>((ref) {
  return ChatUnreadNotifier(
    ref.read(chatRepositoryProvider),
    ref.watch(chatSocketServiceProvider),
  );
});

/// Inbox — danh sách hội thoại (REST). Refresh khi có tin mới qua socket.
final conversationListProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final result = await ref.read(chatRepositoryProvider).getConversations();
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// Chi tiết 1 hội thoại (tên đối phương cho AppBar thread).
final conversationDetailProvider =
    FutureProvider.autoDispose.family<Conversation, String>((ref, id) async {
  final result = await ref.read(chatRepositoryProvider).getConversation(id);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// Thread realtime cho 1 hội thoại.
final chatThreadProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadNotifier, ChatThreadState, String>((ref, conversationId) {
  return ChatThreadNotifier(
    repo: ref.read(chatRepositoryProvider),
    socket: ref.watch(chatSocketServiceProvider),
    conversationId: conversationId,
    myUserId: ref.read(currentUserProvider)?.id ?? '',
  );
});

// ─── Unread badge notifier ────────────────────────────────────────────────────

class ChatUnreadNotifier extends StateNotifier<int> {
  final ChatRepository _repo;
  late final StreamSubscription<ChatSocketEvent> _sub;

  ChatUnreadNotifier(this._repo, ChatSocketService socket) : super(0) {
    refresh();
    _sub = socket.events.listen((e) {
      if (e is MessageNewEvent ||
          e is ReadUpdateEvent ||
          e is SocketConnected) {
        refresh();
      }
    });
  }

  Future<void> refresh() async {
    final result = await _repo.getUnreadCount();
    if (mounted && result.success) state = result.data ?? 0;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─── Thread state + notifier ──────────────────────────────────────────────────

class ChatThreadState {
  final List<ChatMessage> messages; // oldest-first
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? nextCursor;
  final String? error;

  const ChatThreadState({
    this.messages = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.nextCursor,
    this.error,
  });

  ChatThreadState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? nextCursor,
    String? error,
  }) =>
      ChatThreadState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        nextCursor: nextCursor ?? this.nextCursor,
        error: error,
      );
}

class ChatThreadNotifier extends StateNotifier<ChatThreadState> {
  final ChatRepository _repo;
  final ChatSocketService _socket;
  final String conversationId;
  final String myUserId;
  late final StreamSubscription<ChatSocketEvent> _sub;

  ChatThreadNotifier({
    required ChatRepository repo,
    required ChatSocketService socket,
    required this.conversationId,
    required this.myUserId,
  })  : _repo = repo,
        _socket = socket,
        super(const ChatThreadState()) {
    _sub = _socket.events.listen(_onEvent);
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getMessages(conversationId);
    if (!mounted) return;
    if (result.success) {
      final page = result.data!;
      state = state.copyWith(
        loading: false,
        messages: page.messages,
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
      );
      _markRead();
    } else {
      state = state.copyWith(loading: false, error: result.message);
    }
  }

  /// Tải thêm tin cũ hơn (cursor) — prepend lên đầu danh sách.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.nextCursor == null) return;
    state = state.copyWith(loadingMore: true);
    final result =
        await _repo.getMessages(conversationId, cursor: state.nextCursor);
    if (!mounted) return;
    if (result.success) {
      final page = result.data!;
      state = state.copyWith(
        loadingMore: false,
        messages: [...page.messages, ...state.messages],
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
      );
    } else {
      state = state.copyWith(loadingMore: false);
    }
  }

  /// Gửi tin: optimistic trước, reconcile qua `message:ack`/`message:new`.
  /// Socket rớt → fallback REST.
  Future<void> send(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    final localKey = DateTime.now().microsecondsSinceEpoch.toString();
    final optimistic = ChatMessage(
      id: 'local_$localKey',
      conversationId: conversationId,
      senderId: myUserId,
      content: text,
      createdAt: DateTime.now(),
      sendStatus: MessageSendStatus.sending,
      localKey: localKey,
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);

    if (_socket.isConnected) {
      _socket.sendMessage(conversationId, text);
      return; // ack/new sẽ thay thế optimistic
    }
    // Fallback REST khi socket chưa kết nối.
    final result = await _repo.sendMessage(conversationId, content: text);
    if (!mounted) return;
    _replaceLocal(
      localKey,
      result.success
          ? result.data!
          : optimistic.copyWith(sendStatus: MessageSendStatus.failed),
    );
  }

  void _onEvent(ChatSocketEvent e) {
    switch (e) {
      case MessageNewEvent(:final conversationId, :final message)
          when conversationId == this.conversationId:
        _upsertIncoming(message);
      case MessageAckEvent(:final localContent, :final message)
          when message.conversationId == conversationId:
        _reconcile(localContent, message);
      case MessageEditEvent(
            :final conversationId,
            :final messageId,
            :final content,
            :final editedAt
          )
          when conversationId == this.conversationId:
        _applyEdit(messageId, content, editedAt);
      case MessageDeleteEvent(:final conversationId, :final messageId)
          when conversationId == this.conversationId:
        _applyDelete(messageId);
      default:
        break;
    }
  }

  void _upsertIncoming(ChatMessage m) {
    final list = [...state.messages];
    final byId = list.indexWhere((x) => x.id == m.id);
    if (byId >= 0) {
      list[byId] = m;
    } else {
      final optimistic = m.senderId == myUserId
          ? list.indexWhere((x) =>
              x.sendStatus == MessageSendStatus.sending &&
              x.content == m.content)
          : -1;
      if (optimistic >= 0) {
        list[optimistic] = m;
      } else {
        list.add(m);
      }
    }
    state = state.copyWith(messages: list);
    if (m.senderId != myUserId) _markRead();
  }

  void _reconcile(String localContent, ChatMessage m) {
    final list = [...state.messages];
    final idx = list.indexWhere((x) =>
        x.sendStatus == MessageSendStatus.sending && x.content == localContent);
    if (idx >= 0) {
      list[idx] = m;
      state = state.copyWith(messages: list);
    } else if (list.indexWhere((x) => x.id == m.id) < 0) {
      state = state.copyWith(messages: [...list, m]);
    }
  }

  void _replaceLocal(String localKey, ChatMessage m) {
    final list = [...state.messages];
    final idx = list.indexWhere((x) => x.localKey == localKey);
    if (idx >= 0) {
      list[idx] = m;
      state = state.copyWith(messages: list);
    }
  }

  void _applyEdit(String messageId, String content, DateTime? editedAt) {
    final list = [...state.messages];
    final idx = list.indexWhere((x) => x.id == messageId);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(content: content, editedAt: editedAt);
      state = state.copyWith(messages: list);
    }
  }

  void _applyDelete(String messageId) {
    final list = [...state.messages];
    final idx = list.indexWhere((x) => x.id == messageId);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(deletedAt: DateTime.now());
      state = state.copyWith(messages: list);
    }
  }

  void _markRead() {
    _repo.markRead(conversationId);
    if (_socket.isConnected) _socket.markRead(conversationId);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
