import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../data/models/message_model.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Tin mới / ack từ server (xem API §17.4).
typedef SocketMessageEvent = ({String conversationId, MessageModel message});

/// Tin bị xoá.
typedef SocketDeleteEvent = ({String conversationId, String messageId});

/// Member khác đã đọc tới mốc [lastReadAt].
typedef SocketReadEvent = ({
  String conversationId,
  String userId,
  DateTime? lastReadAt,
});

/// Member khác đang gõ / dừng gõ.
typedef SocketTypingEvent = ({
  String conversationId,
  String userId,
  bool typing,
});

/// Member online/offline (chỉ broadcast trong conversation chung).
typedef SocketPresenceEvent = ({String userId, bool online});

/// Service singleton quản lý kết nối WebSocket socket.io tới namespace `/chat`
/// (xem API §17.4). 1 connection / phiên đăng nhập, dùng chung mọi màn chat.
///
/// Lifecycle: `connect()` sau khi login, `disconnect()` khi logout — wire ở
/// `AuthNotifier`. UI/controller lắng qua các stream `on*`.
class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  io.Socket? _socket;

  final _messageNew = StreamController<SocketMessageEvent>.broadcast();
  final _messageAck = StreamController<SocketMessageEvent>.broadcast();
  final _messageEdit = StreamController<SocketMessageEvent>.broadcast();
  final _messageDelete = StreamController<SocketDeleteEvent>.broadcast();
  final _readUpdate = StreamController<SocketReadEvent>.broadcast();
  final _typing = StreamController<SocketTypingEvent>.broadcast();
  final _presence = StreamController<SocketPresenceEvent>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  Stream<SocketMessageEvent> get onMessageNew => _messageNew.stream;
  Stream<SocketMessageEvent> get onMessageAck => _messageAck.stream;
  Stream<SocketMessageEvent> get onMessageEdit => _messageEdit.stream;
  Stream<SocketDeleteEvent> get onMessageDelete => _messageDelete.stream;
  Stream<SocketReadEvent> get onReadUpdate => _readUpdate.stream;
  Stream<SocketTypingEvent> get onTyping => _typing.stream;
  Stream<SocketPresenceEvent> get onPresence => _presence.stream;

  /// True khi socket vừa connect, false khi disconnect — dùng cho banner
  /// "đang kết nối lại" + để controller fallback REST.
  Stream<bool> get onConnectionChange => _connection.stream;
  Stream<String> get onError => _errors.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Mở kết nối với JWT hiện tại. Idempotent — gọi lại khi đã có socket sẽ
  /// no-op. Không throw: lỗi kết nối phát qua [onError].
  Future<void> connect() async {
    if (_socket != null) return;
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final socket = io.io(
      '${ApiConstants.baseUrl}${ApiConstants.chatSocketNamespace}',
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
    _bindEvents(socket);
    socket.connect();
  }

  void _bindEvents(io.Socket socket) {
    socket.onConnect((_) {
      if (kDebugMode) debugPrint('[ChatSocket] connected');
      _connection.add(true);
    });
    socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('[ChatSocket] disconnected');
      _connection.add(false);
    });
    // Trước mỗi lần reconnect, cập nhật token mới nhất (đề phòng access token
    // đã được refresh trong lúc socket rớt).
    socket.onReconnectAttempt((_) => unawaited(_refreshAuthToken()));

    socket.on('message:new', (d) => _emitMessage(_messageNew, d));
    socket.on('message:ack', (d) => _emitAck(d));
    socket.on('message:edit', (d) => _emitMessage(_messageEdit, d));
    socket.on('message:delete', (d) => _emitDelete(d));
    socket.on('read:update', (d) => _emitRead(d));
    socket.on('typing', (d) => _emitTyping(d));
    socket.on('presence', (d) => _emitPresence(d));
    socket.on('error', (d) {
      final msg = _readString(d, 'message') ?? d?.toString() ?? 'Lỗi chat';
      _errors.add(msg);
    });
  }

  Future<void> _refreshAuthToken() async {
    final token = await SecureStorage.getAccessToken();
    final socket = _socket;
    if (token != null && token.isNotEmpty && socket != null) {
      socket.auth = {'token': token};
    }
  }

  // ── Emit (client → server) ────────────────────────────────────────────────

  /// Gửi tin qua WS. Server trả `message:ack` (cho sender) + `message:new`.
  void sendMessage(
    String conversationId, {
    required String content,
    List<MessageAttachment> attachments = const [],
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

  /// Đóng kết nối khi logout. Giữ các StreamController sống (singleton) để lần
  /// login sau dùng lại.
  void disconnect() {
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      socket.clearListeners();
      socket.dispose();
    }
    _connection.add(false);
  }

  // ── Parsing helpers ─────────────────────────────────────────────────────

  void _emitMessage(
    StreamController<SocketMessageEvent> target,
    dynamic data,
  ) {
    final map = _asMap(data);
    if (map == null) return;
    final rawMsg = _asMap(map['message']);
    if (rawMsg == null) return;
    final message = MessageModel.fromJson(rawMsg);
    final convId = map['conversationId'] as String? ?? message.conversationId;
    if (convId.isEmpty) return;
    target.add((conversationId: convId, message: message));
  }

  void _emitAck(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final rawMsg = _asMap(map['message']);
    if (rawMsg == null) return;
    final message = MessageModel.fromJson(rawMsg);
    _messageAck.add((
      conversationId: message.conversationId,
      message: message,
    ));
  }

  void _emitDelete(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final convId = map['conversationId'] as String?;
    final messageId = map['messageId'] as String?;
    if (convId == null || messageId == null) return;
    _messageDelete.add((conversationId: convId, messageId: messageId));
  }

  void _emitRead(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final convId = map['conversationId'] as String?;
    final userId = map['userId'] as String?;
    if (convId == null || userId == null) return;
    _readUpdate.add((
      conversationId: convId,
      userId: userId,
      lastReadAt:
          DateTime.tryParse(map['lastReadAt']?.toString() ?? '')?.toLocal(),
    ));
  }

  void _emitTyping(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final convId = map['conversationId'] as String?;
    final userId = map['userId'] as String?;
    if (convId == null || userId == null) return;
    _typing.add((
      conversationId: convId,
      userId: userId,
      typing: map['typing'] as bool? ?? false,
    ));
  }

  void _emitPresence(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final userId = map['userId'] as String?;
    if (userId == null) return;
    _presence.add((userId: userId, online: map['online'] as bool? ?? false));
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String? _readString(dynamic data, String key) {
    final map = _asMap(data);
    return map?[key] as String?;
  }
}
