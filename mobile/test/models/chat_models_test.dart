import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/conversation_model.dart';
import 'package:mobile/data/models/message_model.dart';

void main() {
  group('sanitizeHttpsUrl', () {
    test('keeps valid https url', () {
      expect(sanitizeHttpsUrl('https://x.com/a.jpg'), 'https://x.com/a.jpg');
    });

    test('rejects http / file / empty / malformed', () {
      expect(sanitizeHttpsUrl('http://x.com/a.jpg'), '');
      expect(sanitizeHttpsUrl('file:///etc/passwd'), '');
      expect(sanitizeHttpsUrl(''), '');
      expect(sanitizeHttpsUrl(null), '');
      expect(sanitizeHttpsUrl('https://'), ''); // no authority
    });

    test('MessageAttachment drops non-https url', () {
      final att = MessageAttachment.fromJson({
        'url': 'http://evil/a.jpg',
        'type': 'image/jpeg',
      });
      expect(att.url, '');
    });

    test('ChatUser drops non-https avatar', () {
      final u = ChatUser.fromJson({
        'id': 'u1',
        'name': 'A',
        'avatar': 'http://evil/a.png',
      });
      expect(u.avatar, isNull);
    });
  });

  group('ConversationType.fromApi', () {
    test('parses known values', () {
      expect(ConversationType.fromApi('booking'), ConversationType.booking);
      expect(ConversationType.fromApi('support'), ConversationType.support);
      expect(ConversationType.fromApi('staff'), ConversationType.staff);
    });

    test('falls back to booking for unknown/null', () {
      expect(ConversationType.fromApi(null), ConversationType.booking);
      expect(ConversationType.fromApi('weird'), ConversationType.booking);
    });
  });

  group('ConversationModel.fromJson', () {
    final json = {
      'id': 'c1',
      'type': 'booking',
      'bookingId': 'b1',
      'subject': null,
      'lastMessageAt': '2026-06-04T10:30:00.000Z',
      'lastMessagePreview': 'Chào bạn',
      'lastSenderId': 'u2',
      'hasDispute': false,
      'members': [
        {
          'userId': 'u1',
          'role': 'owner',
          'unreadCount': 0,
          'user': {'id': 'u1', 'name': 'Chủ nhà'},
        },
        {
          'userId': 'u2',
          'role': 'customer',
          'unreadCount': 3,
          'user': {'id': 'u2', 'name': 'Khách A', 'avatar': 'https://x/y.png'},
        },
      ],
      'myUnread': 3,
    };

    test('parses fields and members', () {
      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 'c1');
      expect(conv.type, ConversationType.booking);
      expect(conv.bookingId, 'b1');
      expect(conv.myUnread, 3);
      expect(conv.hasUnread, isTrue);
      expect(conv.members.length, 2);
      expect(conv.lastMessageAt, isNotNull);
    });

    test('counterpart returns the other member', () {
      final conv = ConversationModel.fromJson(json);
      expect(conv.counterpart('u1')?.userId, 'u2');
      expect(conv.counterpart('u2')?.userId, 'u1');
    });

    test('displayTitle uses subject when present', () {
      final conv = ConversationModel.fromJson({
        ...json,
        'subject': 'Hỗ trợ đặt phòng',
      });
      expect(conv.displayTitle('u1'), 'Hỗ trợ đặt phòng');
    });

    test('displayTitle falls back to counterpart name', () {
      final conv = ConversationModel.fromJson(json);
      expect(conv.displayTitle('u1'), 'Khách A');
    });

    test('copyWith zeroing unread keeps other fields', () {
      final conv = ConversationModel.fromJson(json).copyWith(myUnread: 0);
      expect(conv.myUnread, 0);
      expect(conv.hasUnread, isFalse);
      expect(conv.id, 'c1');
      expect(conv.members.length, 2);
    });

    test('handles missing members gracefully', () {
      final conv = ConversationModel.fromJson({'id': 'x', 'type': 'support'});
      expect(conv.members, isEmpty);
      expect(conv.myUnread, 0);
      expect(conv.displayTitle('me'), 'Hỗ trợ');
    });
  });

  group('MessageModel', () {
    test('fromJson parses attachments + flags', () {
      final msg = MessageModel.fromJson({
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 'u2',
        'content': 'Xin chào',
        'attachments': [
          {'url': 'https://x/a.jpg', 'type': 'image/jpeg', 'name': 'a.jpg'},
        ],
        'isSystem': false,
        'editedAt': null,
        'deletedAt': null,
        'createdAt': '2026-06-04T10:30:00.000Z',
      });
      expect(msg.id, 'm1');
      expect(msg.content, 'Xin chào');
      expect(msg.hasAttachments, isTrue);
      expect(msg.attachments.first.isImage, isTrue);
      expect(msg.isDeleted, isFalse);
      expect(msg.isEdited, isFalse);
      expect(msg.sendStatus, MessageSendStatus.sent);
    });

    test('isDeleted / isEdited reflect timestamps', () {
      final msg = MessageModel.fromJson({
        'id': 'm2',
        'conversationId': 'c1',
        'senderId': 'u2',
        'content': 'x',
        'editedAt': '2026-06-04T11:00:00.000Z',
        'deletedAt': '2026-06-04T12:00:00.000Z',
        'createdAt': '2026-06-04T10:30:00.000Z',
      });
      expect(msg.isEdited, isTrue);
      expect(msg.isDeleted, isTrue);
    });

    test('optimistic factory sets sending + localId', () {
      final msg = MessageModel.optimistic(
        localId: 'local_1',
        conversationId: 'c1',
        senderId: 'u1',
        content: 'hi',
        createdAt: DateTime(2026, 6, 4),
      );
      expect(msg.sendStatus, MessageSendStatus.sending);
      expect(msg.localId, 'local_1');
      expect(msg.id, 'local_1');
    });

    test('copyWith updates status without losing identity', () {
      final msg = MessageModel.optimistic(
        localId: 'local_1',
        conversationId: 'c1',
        senderId: 'u1',
        content: 'hi',
        createdAt: DateTime(2026, 6, 4),
      ).copyWith(sendStatus: MessageSendStatus.failed);
      expect(msg.sendStatus, MessageSendStatus.failed);
      expect(msg.localId, 'local_1');
      expect(msg.content, 'hi');
    });
  });
}
