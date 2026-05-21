import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/notification_model.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('parses all fields correctly when all present', () {
      final json = {
        'id': 'notif-1',
        'title': 'Booking mới',
        'subtitle': 'Phòng 101 đã được đặt',
        'type': 'booking',
        'isRead': false,
        'createdAt': '2026-04-01T08:00:00.000Z',
        'targetId': 'booking-abc',
        'targetType': 'booking',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-1');
      expect(model.title, 'Booking mới');
      expect(model.subtitle, 'Phòng 101 đã được đặt');
      expect(model.type, NotificationType.booking);
      expect(model.isRead, false);
      expect(model.targetId, 'booking-abc');
      expect(model.targetType, 'booking');
    });

    test('returns empty string when id is null', () {
      final json = {
        'title': 'Test',
        'subtitle': '',
        'type': 'system',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, '');
    });

    test('returns empty string when title is null', () {
      final json = {
        'id': 'notif-2',
        'subtitle': 'Sub',
        'type': 'system',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.title, '');
    });

    test('does not crash when createdAt is null', () {
      final json = {
        'id': 'notif-3',
        'title': 'T',
        'subtitle': 'S',
        'type': 'system',
        'createdAt': null,
      };

      expect(() => NotificationModel.fromJson(json), returnsNormally);
      final model = NotificationModel.fromJson(json);
      expect(model.createdAt, isA<DateTime>());
    });

    test('does not crash when createdAt is invalid string', () {
      final json = {
        'id': 'notif-4',
        'title': 'T',
        'subtitle': 'S',
        'type': 'system',
        'createdAt': 'not-a-date',
      };

      expect(() => NotificationModel.fromJson(json), returnsNormally);
      final model = NotificationModel.fromJson(json);
      expect(model.createdAt, isA<DateTime>());
    });

    test('falls back to system when type is invalid', () {
      final json = {
        'id': 'notif-5',
        'title': 'T',
        'subtitle': 'S',
        'type': 'unknown_type',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.type, NotificationType.system);
    });

    test('falls back to system when type is null', () {
      final json = {
        'id': 'notif-6',
        'title': 'T',
        'subtitle': 'S',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.type, NotificationType.system);
    });

    test('parses type booking correctly', () {
      final json = {
        'id': 'n',
        'title': 'T',
        'subtitle': 'S',
        'type': 'booking',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.type, NotificationType.booking);
    });

    test('parses type payment correctly', () {
      final json = {
        'id': 'n',
        'title': 'T',
        'subtitle': 'S',
        'type': 'payment',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.type, NotificationType.payment);
    });

    test('parses type system correctly', () {
      final json = {
        'id': 'n',
        'title': 'T',
        'subtitle': 'S',
        'type': 'system',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.type, NotificationType.system);
    });

    test('isRead defaults to false when missing', () {
      final json = {
        'id': 'n',
        'title': 'T',
        'subtitle': 'S',
        'type': 'system',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.isRead, false);
    });

    test('targetId and targetType are null when missing', () {
      final json = {
        'id': 'n',
        'title': 'T',
        'subtitle': 'S',
        'type': 'system',
        'createdAt': '2026-04-01T08:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.targetId, isNull);
      expect(model.targetType, isNull);
    });
  });

  group('NotificationModel.toJson roundtrip', () {
    test('serializes and deserializes back to equal values', () {
      final original = NotificationModel(
        id: 'notif-99',
        title: 'Tiêu đề',
        subtitle: 'Mô tả phụ',
        type: NotificationType.payment,
        isRead: true,
        createdAt: DateTime.parse('2026-04-01T08:00:00.000Z'),
        targetId: 'pay-001',
        targetType: 'payment',
      );

      final json = original.toJson();
      final parsed = NotificationModel.fromJson(json);

      expect(parsed.id, original.id);
      expect(parsed.title, original.title);
      expect(parsed.subtitle, original.subtitle);
      expect(parsed.type, original.type);
      expect(parsed.isRead, original.isRead);
      expect(parsed.targetId, original.targetId);
      expect(parsed.targetType, original.targetType);
    });
  });

  group('NotificationModel.copyWith', () {
    test('copyWith(isRead: true) updates isRead and keeps other fields', () {
      final original = NotificationModel(
        id: 'notif-10',
        title: 'Tiêu đề',
        subtitle: 'Sub',
        type: NotificationType.booking,
        isRead: false,
        createdAt: DateTime(2026, 4, 1),
      );

      final updated = original.copyWith(isRead: true);

      expect(updated.isRead, true);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.subtitle, original.subtitle);
      expect(updated.type, original.type);
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith without args preserves all fields', () {
      final original = NotificationModel(
        id: 'notif-11',
        title: 'T',
        subtitle: 'S',
        type: NotificationType.system,
        isRead: true,
        createdAt: DateTime(2026, 5, 1),
        targetId: 't-id',
        targetType: 'room',
      );

      final copy = original.copyWith();

      expect(copy.isRead, original.isRead);
      expect(copy.targetId, original.targetId);
    });
  });

  group('NotificationTypeX.label', () {
    test('booking label is correct Vietnamese string', () {
      expect(NotificationType.booking.label, 'Booking');
    });

    test('payment label is correct Vietnamese string', () {
      expect(NotificationType.payment.label, 'Thanh toán');
    });

    test('system label is correct Vietnamese string', () {
      expect(NotificationType.system.label, 'Hệ thống');
    });
  });
}
