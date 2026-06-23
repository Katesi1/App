import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/models/account_deletion_schedule.dart';

void main() {
  group('AccountDeletionSchedule', () {
    test('fromJson parses scheduledDeleteAt and graceDays', () {
      final schedule = AccountDeletionSchedule.fromJson({
        'scheduledDeleteAt': '2026-07-13T10:00:00.000Z',
        'graceDays': 30,
      });

      expect(schedule.scheduledDeleteAt, DateTime.utc(2026, 7, 13, 10));
      expect(schedule.graceDays, 30);
    });

    test('graceDays defaults to 30 when missing', () {
      final schedule = AccountDeletionSchedule.fromJson({
        'scheduledDeleteAt': '2026-07-13T10:00:00.000Z',
      });

      expect(schedule.graceDays, AccountDeletionSchedule.defaultGraceDays);
      expect(schedule.graceDays, 30);
    });
  });
}
