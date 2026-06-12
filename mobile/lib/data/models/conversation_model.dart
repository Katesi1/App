import 'package:equatable/equatable.dart';

/// Loại conversation (xem API §17.1). `booking` = khách ↔ chủ homestay theo 1
/// booking; `support` = user ↔ admin; `staff` = chủ ↔ nhân viên.
enum ConversationType {
  booking,
  support,
  staff;

  static ConversationType fromApi(String? value) {
    return switch (value?.toLowerCase()) {
      'booking' => ConversationType.booking,
      'support' => ConversationType.support,
      'staff' => ConversationType.staff,
      _ => ConversationType.booking,
    };
  }

  String get label => switch (this) {
        ConversationType.booking => 'Đặt phòng',
        ConversationType.support => 'Hỗ trợ',
        ConversationType.staff => 'Nội bộ',
      };
}

/// Thông tin user rút gọn nhúng trong member (xem API §17.2).
class ChatUser extends Equatable {
  final String id;
  final String name;
  final String? avatar;

  const ChatUser({required this.id, required this.name, this.avatar});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Người dùng',
      avatar: json['avatar'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, avatar];
}

/// 1 thành viên trong conversation (xem API §17.2).
class ConversationMember extends Equatable {
  final String userId;
  final String role;
  final DateTime? lastReadAt;
  final int unreadCount;
  final ChatUser? user;

  const ConversationMember({
    required this.userId,
    required this.role,
    this.lastReadAt,
    this.unreadCount = 0,
    this.user,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return ConversationMember(
      userId: json['userId'] as String? ?? '',
      role: json['role'] as String? ?? '',
      lastReadAt: _parseDateOrNull(json['lastReadAt']),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      user: rawUser is Map<String, dynamic> ? ChatUser.fromJson(rawUser) : null,
    );
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  @override
  List<Object?> get props => [userId, role, lastReadAt, unreadCount, user];
}

/// 1 conversation trong inbox (xem API §17.2 ConversationDto).
class ConversationModel extends Equatable {
  final String id;
  final ConversationType type;
  final String? bookingId;
  final String? propertyId;
  final String? subject;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastSenderId;
  final bool hasDispute;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final List<ConversationMember> members;
  final int myUnread;

  const ConversationModel({
    required this.id,
    required this.type,
    this.bookingId,
    this.propertyId,
    this.subject,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastSenderId,
    this.hasDispute = false,
    this.archivedAt,
    this.createdAt,
    this.members = const [],
    this.myUnread = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      type: ConversationType.fromApi(json['type'] as String?),
      bookingId: json['bookingId'] as String?,
      propertyId: json['propertyId'] as String?,
      subject: json['subject'] as String?,
      lastMessageAt: _parseDateOrNull(json['lastMessageAt']),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastSenderId: json['lastSenderId'] as String?,
      hasDispute: json['hasDispute'] as bool? ?? false,
      archivedAt: _parseDateOrNull(json['archivedAt']),
      createdAt: _parseDateOrNull(json['createdAt']),
      members: (json['members'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ConversationMember.fromJson)
          .toList(),
      myUnread: (json['myUnread'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  /// Thành viên đối phương (member đầu tiên khác [currentUserId]) — dùng để
  /// render tên + avatar header inbox. Null nếu chỉ có 1 member.
  ConversationMember? counterpart(String currentUserId) {
    for (final m in members) {
      if (m.userId != currentUserId) return m;
    }
    return members.isEmpty ? null : members.first;
  }

  /// Tên hiển thị: subject nếu có, ngược lại tên đối phương, fallback theo type.
  String displayTitle(String currentUserId) {
    final subj = subject?.trim();
    if (subj != null && subj.isNotEmpty) return subj;
    final other = counterpart(currentUserId);
    final name = other?.user?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return type.label;
  }

  bool get hasUnread => myUnread > 0;

  ConversationModel copyWith({
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? lastSenderId,
    int? myUnread,
    bool? hasDispute,
  }) {
    return ConversationModel(
      id: id,
      type: type,
      bookingId: bookingId,
      propertyId: propertyId,
      subject: subject,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      hasDispute: hasDispute ?? this.hasDispute,
      archivedAt: archivedAt,
      createdAt: createdAt,
      members: members,
      myUnread: myUnread ?? this.myUnread,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        bookingId,
        propertyId,
        subject,
        lastMessageAt,
        lastMessagePreview,
        lastSenderId,
        hasDispute,
        archivedAt,
        createdAt,
        members,
        myUnread,
      ];
}
