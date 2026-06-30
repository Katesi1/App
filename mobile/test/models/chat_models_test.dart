import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/data/models/conversation_model.dart';
import 'package:mobile/features/chat/data/models/message_model.dart';

void main() {
  group('ChatMessage.fromJson', () {
    test('parses message with attachments', () {
      final msg = ChatMessage.fromJson({
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 'u1',
        'content': 'Chào bạn',
        'attachments': [
          {'url': 'https://x/a.jpg', 'type': 'image/jpeg', 'name': 'a.jpg', 'size': 100},
        ],
        'isSystem': false,
        'createdAt': '2026-06-30T07:00:00.000Z',
      });
      expect(msg.id, 'm1');
      expect(msg.content, 'Chào bạn');
      expect(msg.attachments.single.isImage, true);
      expect(msg.isDeleted, false);
      expect(msg.sendStatus, MessageSendStatus.sent);
    });

    test('flags deleted + edited from timestamps', () {
      final msg = ChatMessage.fromJson({
        'id': 'm2',
        'conversationId': 'c1',
        'senderId': 'u1',
        'content': '',
        'editedAt': '2026-06-30T07:05:00.000Z',
        'deletedAt': '2026-06-30T07:06:00.000Z',
      });
      expect(msg.isEdited, true);
      expect(msg.isDeleted, true);
    });

    test('copyWith updates send status without losing fields', () {
      const msg = ChatMessage(
        id: 'local_1',
        conversationId: 'c1',
        senderId: 'u1',
        content: 'hi',
        sendStatus: MessageSendStatus.sending,
        localKey: 'k1',
      );
      final failed = msg.copyWith(sendStatus: MessageSendStatus.failed);
      expect(failed.sendStatus, MessageSendStatus.failed);
      expect(failed.localKey, 'k1');
      expect(failed.content, 'hi');
    });
  });

  group('Conversation', () {
    final json = {
      'id': 'c1',
      'type': 'booking',
      'bookingId': 'b1',
      'lastMessagePreview': 'Phòng còn trống không?',
      'myUnread': 3,
      'members': [
        {
          'userId': 'me',
          'role': 'owner',
          'user': {'id': 'me', 'name': 'Chủ nhà'},
        },
        {
          'userId': 'cust',
          'role': 'customer',
          'user': {'id': 'cust', 'name': 'Khách A'},
        },
      ],
    };

    test('parses + typeLabel', () {
      final c = Conversation.fromJson(json);
      expect(c.id, 'c1');
      expect(c.myUnread, 3);
      expect(c.typeLabel, 'Đặt phòng');
      expect(c.members.length, 2);
    });

    test('titleFor returns the counterpart name, not mine', () {
      final c = Conversation.fromJson(json);
      expect(c.titleFor('me'), 'Khách A');
      expect(c.counterpart('me')?.userId, 'cust');
    });
  });
}
