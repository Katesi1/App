import 'package:equatable/equatable.dart';

/// Trạng thái gửi phía client cho optimistic UI. Tin từ BE luôn là [sent].
enum MessageSendStatus { sending, sent, failed }

/// File đính kèm trong 1 message (xem API §17.3). BE validate: URL phải
/// `https://`, tối đa 5 file/tin.
class MessageAttachment extends Equatable {
  final String url;
  final String type;
  final String? name;
  final int? size;

  const MessageAttachment({
    required this.url,
    required this.type,
    this.name,
    this.size,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? '',
      name: json['name'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type,
        if (name != null) 'name': name,
        if (size != null) 'size': size,
      };

  bool get isImage => type.startsWith('image/');

  @override
  List<Object?> get props => [url, type, name, size];
}

/// 1 tin nhắn trong conversation (xem API §17.3 MessageDto).
///
/// [localId] + [sendStatus] là field client-side cho optimistic UI — không
/// gửi lên BE. Tin do BE trả về có [sendStatus] = [MessageSendStatus.sent] và
/// [localId] = null.
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final List<MessageAttachment> attachments;
  final bool isSystem;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;

  /// Client-only — id tạm cho tin optimistic chưa có id thật từ server.
  final String? localId;

  /// Client-only — trạng thái gửi để render spinner/retry.
  final MessageSendStatus sendStatus;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.attachments = const [],
    this.isSystem = false,
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
    this.localId,
    this.sendStatus = MessageSendStatus.sent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      attachments: (json['attachments'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MessageAttachment.fromJson)
          .toList(),
      isSystem: json['isSystem'] as bool? ?? false,
      editedAt: _parseDateOrNull(json['editedAt']),
      deletedAt: _parseDateOrNull(json['deletedAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  /// Tạo tin optimistic (chưa gửi) phía client.
  factory MessageModel.optimistic({
    required String localId,
    required String conversationId,
    required String senderId,
    required String content,
    required DateTime createdAt,
    List<MessageAttachment> attachments = const [],
  }) {
    return MessageModel(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      attachments: attachments,
      createdAt: createdAt,
      localId: localId,
      sendStatus: MessageSendStatus.sending,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString())?.toLocal() ?? DateTime.now();
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get hasAttachments => attachments.isNotEmpty;

  MessageModel copyWith({
    String? id,
    String? content,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? localId,
    MessageSendStatus? sendStatus,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      content: content ?? this.content,
      attachments: attachments,
      isSystem: isSystem,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      localId: localId ?? this.localId,
      sendStatus: sendStatus ?? this.sendStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        attachments,
        isSystem,
        editedAt,
        deletedAt,
        createdAt,
        localId,
        sendStatus,
      ];
}
