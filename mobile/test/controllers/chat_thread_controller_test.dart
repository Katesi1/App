import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/data/models/message_model.dart';
import 'package:mobile/data/repositories/chat_repository.dart';
import 'package:mobile/features/chat/controllers/chat_thread_controller.dart';

MessageModel _msg(
  String id, {
  String content = 'x',
  String sender = 'them',
}) {
  return MessageModel(
    id: id,
    conversationId: 'c1',
    senderId: sender,
    content: content,
    createdAt: DateTime(2026, 6, 4, 10),
  );
}

/// Fake repo override các method REST. Không gọi mạng thật.
class _FakeChatRepo extends ChatRepository {
  _FakeChatRepo({
    required this.messagesByCursor,
    this.sendResult,
  });

  /// key = cursor (null = initial), value = page trả về.
  final Map<String?, MessagePage> messagesByCursor;
  ApiResponse<MessageModel>? sendResult;
  int sendCalls = 0;
  int deleteCalls = 0;

  @override
  Future<ApiResponse<void>> deleteMessage(String messageId) async {
    deleteCalls++;
    return ApiResponse(success: true, message: '');
  }

  @override
  Future<ApiResponse<MessagePage>> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 30,
  }) async {
    final page = messagesByCursor[cursor] ??
        (messages: <MessageModel>[], nextCursor: null);
    return ApiResponse(success: true, data: page, message: '');
  }

  @override
  Future<ApiResponse<void>> markRead(String conversationId) async {
    return ApiResponse(success: true, message: '');
  }

  @override
  Future<ApiResponse<MessageModel>> sendMessage(
    String conversationId, {
    required String content,
    List<MessageAttachment> attachments = const [],
  }) async {
    sendCalls++;
    return sendResult ??
        ApiResponse(success: false, message: 'no handler set');
  }
}

ChatThreadNotifier _make(_FakeChatRepo repo) {
  // Socket singleton ở trạng thái disconnected (isConnected=false) → notifier
  // dùng REST fallback. Streams broadcast không emit trong test.
  return ChatThreadNotifier('c1', repo, ChatSocketService.instance, 'me');
}

void main() {
  group('ChatThreadNotifier.loadInitial', () {
    test('populates messages + cursor + hasMore', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {
          null: (messages: [_msg('m1')], nextCursor: 'cur1'),
        },
      );
      final n = _make(repo);
      await n.loadInitial();

      expect(n.state.messages.map((m) => m.id), ['m1']);
      expect(n.state.nextCursor, 'cur1');
      expect(n.state.hasMore, isTrue);
      expect(n.state.isLoadingInitial, isFalse);
      n.dispose();
    });

    test('hasMore false when no cursor', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {
          null: (messages: [_msg('m1')], nextCursor: null),
        },
      );
      final n = _make(repo);
      await n.loadInitial();
      expect(n.state.hasMore, isFalse);
      n.dispose();
    });
  });

  group('ChatThreadNotifier.send (REST fallback)', () {
    test('optimistic message replaced by server message on success', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
        sendResult: ApiResponse(
          success: true,
          data: _msg('sv1', content: 'hello', sender: 'me'),
          message: '',
        ),
      );
      final n = _make(repo);
      await n.loadInitial();
      await n.send('hello');

      expect(n.state.messages.length, 1);
      final m = n.state.messages.single;
      expect(m.id, 'sv1');
      expect(m.sendStatus, MessageSendStatus.sent);
      expect(m.localId, isNull);
      expect(repo.sendCalls, 1);
      n.dispose();
    });

    test('marks message failed when send fails', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
        sendResult: ApiResponse(success: false, message: 'Lỗi mạng'),
      );
      final n = _make(repo);
      await n.loadInitial();
      await n.send('hi');

      expect(n.state.messages.length, 1);
      expect(n.state.messages.single.sendStatus, MessageSendStatus.failed);
      n.dispose();
    });

    test('ignores empty content', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
      );
      final n = _make(repo);
      await n.loadInitial();
      await n.send('   ');
      expect(n.state.messages, isEmpty);
      expect(repo.sendCalls, 0);
      n.dispose();
    });

    test('rejects content over max length', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
      );
      final n = _make(repo);
      await n.loadInitial();
      await n.send('a' * (kMaxChatMessageLength + 1));
      expect(n.state.messages, isEmpty);
      expect(repo.sendCalls, 0);
      n.dispose();
    });
  });

  group('ChatThreadNotifier ownership guards', () {
    test('deleteMessage on other user message is blocked (no REST call)',
        () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
      );
      final n = _make(repo);
      await n.loadInitial();
      final err = await n.deleteMessage(_msg('m1', sender: 'them'));
      expect(err, isNotNull);
      expect(repo.deleteCalls, 0);
      n.dispose();
    });

    test('deleteMessage on own message calls REST', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
      );
      final n = _make(repo);
      await n.loadInitial();
      final mine = MessageModel(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'me',
        content: 'x',
        createdAt: DateTime.now(),
      );
      final err = await n.deleteMessage(mine);
      expect(err, isNull);
      expect(repo.deleteCalls, 1);
      n.dispose();
    });
  });

  group('ChatThreadNotifier.loadMore', () {
    test('prepends older messages and dedups by id', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {
          null: (messages: [_msg('m2')], nextCursor: 'cur1'),
          'cur1': (
            messages: [_msg('m1'), _msg('m2')], // m2 trùng
            nextCursor: null,
          ),
        },
      );
      final n = _make(repo);
      await n.loadInitial();
      await n.loadMore();

      expect(n.state.messages.map((m) => m.id), ['m1', 'm2']);
      expect(n.state.hasMore, isFalse);
      expect(n.state.isLoadingMore, isFalse);
      n.dispose();
    });

    test('no-op when hasMore is false', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {
          null: (messages: [_msg('m1')], nextCursor: null),
        },
      );
      final n = _make(repo);
      await n.loadInitial();
      await n.loadMore();
      expect(n.state.messages.map((m) => m.id), ['m1']);
      n.dispose();
    });
  });

  group('ChatThreadNotifier.canEdit / canDelete', () {
    test('canEdit true only for own recent message', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
      );
      final n = _make(repo);
      final mine = MessageModel(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'me',
        content: 'x',
        createdAt: DateTime.now(),
      );
      final theirs = _msg('m2', sender: 'them');
      expect(n.canEdit(mine), isTrue);
      expect(n.canEdit(theirs), isFalse);
      expect(n.canDelete(mine), isTrue);
      expect(n.canDelete(theirs), isFalse);
      n.dispose();
    });

    test('canEdit false after 15 minutes', () async {
      final repo = _FakeChatRepo(
        messagesByCursor: {null: (messages: [], nextCursor: null)},
      );
      final n = _make(repo);
      final old = MessageModel(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'me',
        content: 'x',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );
      expect(n.canEdit(old), isFalse);
      expect(n.canDelete(old), isTrue); // delete không giới hạn thời gian
      n.dispose();
    });
  });
}
