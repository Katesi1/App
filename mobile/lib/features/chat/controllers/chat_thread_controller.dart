import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/chat_socket_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import 'chat_controller.dart';

/// State của 1 thread chat. `messages` luôn oldest-first (index 0 = cũ nhất).
class ChatThreadState extends Equatable {
  final List<MessageModel> messages;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final String? error;

  /// userId của các member khác đang gõ.
  final Set<String> typingUserIds;

  const ChatThreadState({
    this.messages = const [],
    this.isLoadingInitial = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
    this.error,
    this.typingUserIds = const {},
  });

  ChatThreadState copyWith({
    List<MessageModel>? messages,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    String? error,
    Set<String>? typingUserIds,
  }) {
    return ChatThreadState(
      messages: messages ?? this.messages,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      error: error,
      typingUserIds: typingUserIds ?? this.typingUserIds,
    );
  }

  bool get someoneTyping => typingUserIds.isNotEmpty;

  @override
  List<Object?> get props => [
        messages,
        isLoadingInitial,
        isLoadingMore,
        hasMore,
        nextCursor,
        error,
        typingUserIds,
      ];
}

class ChatThreadNotifier extends StateNotifier<ChatThreadState> {
  ChatThreadNotifier(
    this._conversationId,
    this._repo,
    this._socket,
    this._currentUserId,
  ) : super(const ChatThreadState()) {
    _bindSocket();
    loadInitial();
  }

  final String _conversationId;
  final ChatRepository _repo;
  final ChatSocketService _socket;
  final String? _currentUserId;

  final List<StreamSubscription<dynamic>> _subs = [];
  int _localSeq = 0;

  void _bindSocket() {
    _subs.add(_socket.onMessageNew.listen((e) {
      if (e.conversationId == _conversationId) _onIncoming(e.message);
    }));
    _subs.add(_socket.onMessageAck.listen((e) {
      if (e.conversationId == _conversationId) _onAck(e.message);
    }));
    _subs.add(_socket.onMessageEdit.listen((e) {
      if (e.conversationId == _conversationId) _onEdit(e.message);
    }));
    _subs.add(_socket.onMessageDelete.listen((e) {
      if (e.conversationId == _conversationId) _onDelete(e.messageId);
    }));
    _subs.add(_socket.onTyping.listen((e) {
      if (e.conversationId == _conversationId) _onTyping(e);
    }));
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoadingInitial: true, error: null);
    final result = await _repo.getMessages(_conversationId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      final page = result.data!;
      state = state.copyWith(
        messages: page.messages,
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
        isLoadingInitial: false,
      );
      markRead();
    } else {
      state = state.copyWith(isLoadingInitial: false, error: result.message);
    }
  }

  /// Tải thêm tin cũ hơn (prepend). Trả về để UI giữ scroll offset nếu cần.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    final result = await _repo.getMessages(
      _conversationId,
      cursor: state.nextCursor,
    );
    if (!mounted) return;
    if (result.success && result.data != null) {
      final page = result.data!;
      // Tin cũ hơn → chèn lên đầu, lọc trùng id.
      final existingIds = state.messages.map((m) => m.id).toSet();
      final older =
          page.messages.where((m) => !existingIds.contains(m.id)).toList();
      state = state.copyWith(
        messages: [...older, ...state.messages],
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
        isLoadingMore: false,
      );
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Gửi tin với optimistic UI. Ưu tiên socket; fallback REST khi socket
  /// chưa kết nối.
  Future<void> send(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final userId = _currentUserId;
    if (userId == null) return;

    final localId =
        'local_${_localSeq++}_${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = MessageModel.optimistic(
      localId: localId,
      conversationId: _conversationId,
      senderId: userId,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);

    if (_socket.isConnected) {
      _socket.sendMessage(_conversationId, content: trimmed);
      // Ack/new event sẽ thay thế tin optimistic. Nếu không tới, tin giữ
      // trạng thái "đang gửi" — user có thể gửi lại.
      return;
    }

    // Fallback REST.
    final result = await _repo.sendMessage(_conversationId, content: trimmed);
    if (!mounted) return;
    if (result.success && result.data != null) {
      _replaceLocal(localId, result.data!);
    } else {
      _markFailed(localId);
    }
  }

  /// Gửi lại tin đã fail.
  Future<void> retry(MessageModel failed) async {
    if (failed.localId == null) return;
    _updateById(
      failed.localId!,
      (m) => m.copyWith(sendStatus: MessageSendStatus.sending),
    );
    if (_socket.isConnected) {
      _socket.sendMessage(_conversationId, content: failed.content);
      return;
    }
    final result =
        await _repo.sendMessage(_conversationId, content: failed.content);
    if (!mounted) return;
    if (result.success && result.data != null) {
      _replaceLocal(failed.localId!, result.data!);
    } else {
      _markFailed(failed.localId!);
    }
  }

  Future<void> markRead() async {
    if (_socket.isConnected) _socket.markRead(_conversationId);
    await _repo.markRead(_conversationId);
  }

  /// Sửa tin (chỉ trong 15 phút, chỉ sender — BE enforce). Trả message lỗi nếu
  /// thất bại, null nếu OK.
  Future<String?> editMessage(MessageModel message, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || trimmed == message.content) return null;
    final result = await _repo.editMessage(message.id, content: trimmed);
    if (!mounted) return null;
    if (result.success && result.data != null) {
      _updateById(
        message.id,
        (m) => m.copyWith(
          content: result.data!.content,
          editedAt: result.data!.editedAt ?? DateTime.now(),
        ),
      );
      return null;
    }
    return result.message;
  }

  /// Xoá tin (sender hoặc admin). Soft-delete.
  Future<String?> deleteMessage(MessageModel message) async {
    final result = await _repo.deleteMessage(message.id);
    if (!mounted) return null;
    if (result.success) {
      _updateById(message.id, (m) => m.copyWith(deletedAt: DateTime.now()));
      return null;
    }
    return result.message;
  }

  /// True nếu tin còn trong cửa sổ 15 phút cho phép sửa.
  bool canEdit(MessageModel message) {
    if (message.senderId != _currentUserId || message.isDeleted) return false;
    return DateTime.now().difference(message.createdAt).inMinutes < 15;
  }

  bool canDelete(MessageModel message) =>
      message.senderId == _currentUserId && !message.isDeleted;

  void notifyTyping(bool typing) {
    if (!_socket.isConnected) return;
    if (typing) {
      _socket.typingStart(_conversationId);
    } else {
      _socket.typingStop(_conversationId);
    }
  }

  // ── Socket event handlers ────────────────────────────────────────────────

  void _onIncoming(MessageModel message) {
    // Tin của chính mình từ server → reconcile optimistic.
    if (message.senderId == _currentUserId) {
      if (_reconcileOptimistic(message)) return;
    }
    // Tránh trùng (đã có id).
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(messages: [...state.messages, message]);
    markRead();
  }

  void _onAck(MessageModel message) {
    if (_reconcileOptimistic(message)) return;
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(messages: [...state.messages, message]);
  }

  /// Thay tin optimistic (đang gửi, cùng nội dung) bằng tin server. Trả true
  /// nếu tìm thấy và thay.
  bool _reconcileOptimistic(MessageModel server) {
    final idx = state.messages.indexWhere(
      (m) =>
          m.localId != null &&
          m.sendStatus == MessageSendStatus.sending &&
          m.senderId == server.senderId &&
          m.content == server.content,
    );
    if (idx < 0) return false;
    final updated = [...state.messages];
    updated[idx] = server;
    state = state.copyWith(messages: updated);
    return true;
  }

  void _onEdit(MessageModel edited) {
    _updateById(
      edited.id,
      (m) => m.copyWith(content: edited.content, editedAt: edited.editedAt),
    );
  }

  void _onDelete(String messageId) {
    _updateById(
      messageId,
      (m) => m.copyWith(deletedAt: DateTime.now()),
    );
  }

  void _onTyping(SocketTypingEvent e) {
    if (e.userId == _currentUserId) return;
    final next = {...state.typingUserIds};
    if (e.typing) {
      next.add(e.userId);
    } else {
      next.remove(e.userId);
    }
    state = state.copyWith(typingUserIds: next);
  }

  // ── Local mutation helpers ────────────────────────────────────────────────

  void _replaceLocal(String localId, MessageModel server) {
    final updated = state.messages
        .map((m) => (m.localId == localId || m.id == localId) ? server : m)
        .toList();
    state = state.copyWith(messages: updated);
  }

  void _markFailed(String localId) {
    _updateById(
      localId,
      (m) => m.copyWith(sendStatus: MessageSendStatus.failed),
    );
  }

  void _updateById(
    String idOrLocalId,
    MessageModel Function(MessageModel) transform,
  ) {
    final updated = state.messages
        .map((m) => (m.id == idOrLocalId || m.localId == idOrLocalId)
            ? transform(m)
            : m)
        .toList();
    state = state.copyWith(messages: updated);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

/// Family theo conversationId. autoDispose → đóng thread khi rời màn hình.
final chatThreadProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadNotifier, ChatThreadState, String>((ref, conversationId) {
  return ChatThreadNotifier(
    conversationId,
    ref.read(chatRepositoryProvider),
    ref.read(chatSocketServiceProvider),
    ref.read(currentUserProvider)?.id,
  );
});

/// Detail conversation (header: tên đối phương, type...). autoDispose.
final conversationDetailProvider =
    FutureProvider.autoDispose.family((ref, String id) async {
  final repo = ref.read(chatRepositoryProvider);
  final result = await repo.getConversation(id);
  if (result.success && result.data != null) return result.data!;
  throw Exception(result.message);
});
