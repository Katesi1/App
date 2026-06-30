/// Models hội thoại chat (BE §17.2). Type: booking | support | staff.
library;

/// Thông tin user rút gọn gắn trong member.
class ChatMemberUser {
  final String id;
  final String name;
  final String? avatar;

  const ChatMemberUser({required this.id, required this.name, this.avatar});

  factory ChatMemberUser.fromJson(Map<String, dynamic> j) => ChatMemberUser(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        avatar: j['avatar'] as String?,
      );
}

class ConversationMember {
  final String userId;
  final String role; // owner | sale | customer | admin | support
  final DateTime? lastReadAt;
  final int unreadCount;
  final ChatMemberUser? user;

  const ConversationMember({
    required this.userId,
    required this.role,
    this.lastReadAt,
    this.unreadCount = 0,
    this.user,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> j) =>
      ConversationMember(
        userId: (j['userId'] ?? '') as String,
        role: (j['role'] ?? '') as String,
        lastReadAt: _date(j['lastReadAt']),
        unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
        user: j['user'] is Map<String, dynamic>
            ? ChatMemberUser.fromJson(j['user'] as Map<String, dynamic>)
            : null,
      );
}

class Conversation {
  final String id;
  final String type; // booking | support | staff
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

  const Conversation({
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

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] ?? '') as String,
        type: (j['type'] ?? 'booking') as String,
        bookingId: j['bookingId'] as String?,
        propertyId: j['propertyId'] as String?,
        subject: j['subject'] as String?,
        lastMessageAt: _date(j['lastMessageAt']),
        lastMessagePreview: j['lastMessagePreview'] as String?,
        lastSenderId: j['lastSenderId'] as String?,
        hasDispute: (j['hasDispute'] ?? false) as bool,
        archivedAt: _date(j['archivedAt']),
        createdAt: _date(j['createdAt']),
        members: (j['members'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ConversationMember.fromJson)
                .toList() ??
            const [],
        myUnread: (j['myUnread'] as num?)?.toInt() ?? 0,
      );

  String get typeLabel => switch (type) {
        'booking' => 'Đặt phòng',
        'support' => 'Hỗ trợ',
        'staff' => 'Nội bộ',
        _ => type,
      };

  /// Đối tượng đang chat cùng (member khác mình) để hiện tên + avatar.
  ConversationMember? counterpart(String myUserId) {
    for (final m in members) {
      if (m.userId != myUserId) return m;
    }
    return members.isNotEmpty ? members.first : null;
  }

  /// Tên hiển thị: tên đối phương, fallback subject/typeLabel.
  String titleFor(String myUserId) {
    final other = counterpart(myUserId)?.user?.name;
    if (other != null && other.isNotEmpty) return other;
    if (subject != null && subject!.isNotEmpty) return subject!;
    return typeLabel;
  }

  Conversation copyWith({
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? lastSenderId,
    int? myUnread,
  }) =>
      Conversation(
        id: id,
        type: type,
        bookingId: bookingId,
        propertyId: propertyId,
        subject: subject,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        lastSenderId: lastSenderId ?? this.lastSenderId,
        hasDispute: hasDispute,
        archivedAt: archivedAt,
        createdAt: createdAt,
        members: members,
        myUnread: myUnread ?? this.myUnread,
      );
}

DateTime? _date(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
