/// Models tin nhắn chat (BE §17.3). Realtime qua Socket.IO + REST history.
library;

/// File đính kèm trong 1 tin nhắn — `{ url, type, name, size }`.
class ChatAttachment {
  final String url;
  final String type; // MIME: image/jpeg, application/pdf...
  final String name;
  final int size;

  const ChatAttachment({
    required this.url,
    this.type = '',
    this.name = '',
    this.size = 0,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> j) => ChatAttachment(
        url: (j['url'] ?? '') as String,
        type: (j['type'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        size: (j['size'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        if (type.isNotEmpty) 'type': type,
        if (name.isNotEmpty) 'name': name,
        if (size > 0) 'size': size,
      };

  bool get isImage => type.startsWith('image/');
}

/// Trạng thái gửi của tin nhắn local (optimistic UI).
enum MessageSendStatus { sending, sent, failed }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final List<ChatAttachment> attachments;
  final bool isSystem;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime? createdAt;

  /// Chỉ dùng phía client cho optimistic UI (không tới từ BE).
  final MessageSendStatus sendStatus;

  /// Nội dung local để khớp `message:ack` (BE trả lại `localContent`).
  final String? localKey;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.attachments = const [],
    this.isSystem = false,
    this.editedAt,
    this.deletedAt,
    this.createdAt,
    this.sendStatus = MessageSendStatus.sent,
    this.localKey,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] ?? '') as String,
        conversationId: (j['conversationId'] ?? '') as String,
        senderId: (j['senderId'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        attachments: (j['attachments'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatAttachment.fromJson)
                .toList() ??
            const [],
        isSystem: (j['isSystem'] ?? false) as bool,
        editedAt: _date(j['editedAt']),
        deletedAt: _date(j['deletedAt']),
        createdAt: _date(j['createdAt']),
      );

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;

  ChatMessage copyWith({
    String? id,
    String? content,
    DateTime? editedAt,
    DateTime? deletedAt,
    MessageSendStatus? sendStatus,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        content: content ?? this.content,
        attachments: attachments,
        isSystem: isSystem,
        editedAt: editedAt ?? this.editedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        createdAt: createdAt,
        sendStatus: sendStatus ?? this.sendStatus,
        localKey: localKey,
      );
}

DateTime? _date(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
