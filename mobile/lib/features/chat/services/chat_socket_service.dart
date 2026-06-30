import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/models/message_model.dart';

/// Sự kiện realtime từ server (BE §17.4). Sealed → switch exhaustiveness.
sealed class ChatSocketEvent {
  const ChatSocketEvent();
}

class SocketConnected extends ChatSocketEvent {
  const SocketConnected();
}

class SocketDisconnected extends ChatSocketEvent {
  const SocketDisconnected();
}

/// Tin mới (cả sender + recipient nhận).
class MessageNewEvent extends ChatSocketEvent {
  final String conversationId;
  final ChatMessage message;
  const MessageNewEvent(this.conversationId, this.message);
}

/// Xác nhận tin của sender — map `localContent` → message id thật.
class MessageAckEvent extends ChatSocketEvent {
  final String localContent;
  final ChatMessage message;
  const MessageAckEvent(this.localContent, this.message);
}

class MessageEditEvent extends ChatSocketEvent {
  final String conversationId;
  final String messageId;
  final String content;
  final DateTime? editedAt;
  const MessageEditEvent(
      this.conversationId, this.messageId, this.content, this.editedAt);
}

class MessageDeleteEvent extends ChatSocketEvent {
  final String conversationId;
  final String messageId;
  const MessageDeleteEvent(this.conversationId, this.messageId);
}

class ReadUpdateEvent extends ChatSocketEvent {
  final String conversationId;
  final String userId;
  final DateTime? lastReadAt;
  const ReadUpdateEvent(this.conversationId, this.userId, this.lastReadAt);
}

class TypingEvent extends ChatSocketEvent {
  final String conversationId;
  final String userId;
  final bool typing;
  const TypingEvent(this.conversationId, this.userId, this.typing);
}

class PresenceEvent extends ChatSocketEvent {
  final String userId;
  final bool online;
  const PresenceEvent(this.userId, this.online);
}

/// Singleton wrapper quanh Socket.IO chat namespace (`/chat`).
///
/// Connect 1 lần sau login, disconnect khi logout. Tự refresh access token +
/// reconnect khi BE báo `tokenExpired` (token sống 15'). Phát [ChatSocketEvent]
/// qua [events] để controller lắng.
class ChatSocketService {
  io.Socket? _socket;
  final _controller = StreamController<ChatSocketEvent>.broadcast();
  bool _refreshing = false;

  /// Stream các sự kiện realtime — controller subscribe để cập nhật UI.
  Stream<ChatSocketEvent> get events => _controller.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await SecureStorage.getAccessToken();
    if (token == null) return;

    final url = '${ApiConstants.baseUrl}${ApiConstants.chatSocketNamespace}';
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setQuery({'lang': 'vi'})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .build(),
    );
    _socket = socket;
    _bind(socket);
    socket.connect();
  }

  void _bind(io.Socket socket) {
    socket.onConnect((_) {
      if (kDebugMode) debugPrint('[chat-ws] connected');
      _emit(const SocketConnected());
    });
    socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('[chat-ws] disconnected');
      _emit(const SocketDisconnected());
    });
    socket.on('error', (data) => _onError(data));

    socket.on('message:new', (data) {
      final map = _asMap(data);
      final msg = _asMap(map['message']);
      if (msg.isEmpty) return;
      _emit(MessageNewEvent(
        (map['conversationId'] ?? msg['conversationId'] ?? '') as String,
        ChatMessage.fromJson(msg),
      ));
    });

    socket.on('message:ack', (data) {
      final map = _asMap(data);
      final msg = _asMap(map['message']);
      if (msg.isEmpty) return;
      _emit(MessageAckEvent(
        (map['localContent'] ?? '') as String,
        ChatMessage.fromJson(msg),
      ));
    });

    socket.on('message:edit', (data) {
      final map = _asMap(data);
      final msg = _asMap(map['message']);
      _emit(MessageEditEvent(
        (map['conversationId'] ?? msg['conversationId'] ?? '') as String,
        (msg['id'] ?? '') as String,
        (msg['content'] ?? '') as String,
        _date(msg['editedAt']),
      ));
    });

    socket.on('message:delete', (data) {
      final map = _asMap(data);
      _emit(MessageDeleteEvent(
        (map['conversationId'] ?? '') as String,
        (map['messageId'] ?? '') as String,
      ));
    });

    socket.on('read:update', (data) {
      final map = _asMap(data);
      _emit(ReadUpdateEvent(
        (map['conversationId'] ?? '') as String,
        (map['userId'] ?? '') as String,
        _date(map['lastReadAt']),
      ));
    });

    socket.on('typing', (data) {
      final map = _asMap(data);
      _emit(TypingEvent(
        (map['conversationId'] ?? '') as String,
        (map['userId'] ?? '') as String,
        (map['typing'] ?? false) as bool,
      ));
    });

    socket.on('presence', (data) {
      final map = _asMap(data);
      _emit(PresenceEvent(
        (map['userId'] ?? '') as String,
        (map['online'] ?? false) as bool,
      ));
    });
  }

  /// `error: { code: 'tokenExpired' }` → refresh token rồi reconnect.
  Future<void> _onError(dynamic data) async {
    final map = _asMap(data);
    final code = map['code'];
    if (kDebugMode) debugPrint('[chat-ws] error: $map');
    if (code != 'tokenExpired' || _refreshing) return;
    _refreshing = true;
    try {
      // Chạm 1 endpoint authed → AuthInterceptor tự refresh 401 + lưu token mới.
      try {
        await ApiClient.instance.get(ApiConstants.conversationsUnreadCount);
      } catch (_) {/* refresh side-effect đủ rồi, bỏ qua lỗi data */}
      final fresh = await SecureStorage.getAccessToken();
      if (fresh != null && _socket != null) {
        _socket!.auth = {'token': fresh};
        _socket!
          ..disconnect()
          ..connect();
      }
    } finally {
      _refreshing = false;
    }
  }

  // ── Client → Server ─────────────────────────────────────────────────────

  void sendMessage(
    String conversationId,
    String content, {
    List<ChatAttachment> attachments = const [],
  }) {
    _socket?.emit('message:send', {
      'conversationId': conversationId,
      'content': content,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toJson()).toList(),
    });
  }

  void markRead(String conversationId) {
    _socket?.emit('read', {'conversationId': conversationId});
  }

  void typingStart(String conversationId) {
    _socket?.emit('typing:start', {'conversationId': conversationId});
  }

  void typingStop(String conversationId) {
    _socket?.emit('typing:stop', {'conversationId': conversationId});
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  void _emit(ChatSocketEvent e) {
    if (!_controller.isClosed) _controller.add(e);
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  static DateTime? _date(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
