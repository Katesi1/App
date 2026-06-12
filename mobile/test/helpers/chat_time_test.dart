import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/chat/utils/chat_time.dart';

void main() {
  group('ChatTime.inboxLabel', () {
    test('returns empty for null', () {
      expect(ChatTime.inboxLabel(null), '');
    });

    test('"Vừa xong" for under a minute', () {
      final t = DateTime.now().subtract(const Duration(seconds: 20));
      expect(ChatTime.inboxLabel(t), 'Vừa xong');
    });

    test('"N phút" within the hour', () {
      final t = DateTime.now().subtract(const Duration(minutes: 12));
      expect(ChatTime.inboxLabel(t), '12 phút');
    });

    test('"Hôm qua" for yesterday', () {
      final t = DateTime.now().subtract(const Duration(days: 1));
      expect(ChatTime.inboxLabel(t), 'Hôm qua');
    });
  });

  group('ChatTime.isDifferentDay', () {
    test('same day → false', () {
      expect(
        ChatTime.isDifferentDay(DateTime(2026, 6, 4, 9), DateTime(2026, 6, 4, 18)),
        isFalse,
      );
    });

    test('different day → true', () {
      expect(
        ChatTime.isDifferentDay(DateTime(2026, 6, 4), DateTime(2026, 6, 5)),
        isTrue,
      );
    });
  });

  group('ChatTime.daySeparator', () {
    test('today', () {
      expect(ChatTime.daySeparator(DateTime.now()), 'Hôm nay');
    });

    test('yesterday', () {
      expect(
        ChatTime.daySeparator(DateTime.now().subtract(const Duration(days: 1))),
        'Hôm qua',
      );
    });

    test('older renders dd/MM/yyyy', () {
      expect(ChatTime.daySeparator(DateTime(2024, 1, 15)), '15/01/2024');
    });
  });

  group('ChatTime.messageTime', () {
    test('formats HH:mm', () {
      expect(ChatTime.messageTime(DateTime(2026, 6, 4, 9, 5)), '09:05');
    });
  });
}
