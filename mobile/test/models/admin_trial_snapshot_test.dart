import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/admin/data/models/trial_snapshot.dart';

void main() {
  group('TrialSnapshot.fromJson', () {
    test('parses all fields correctly when all present', () {
      final json = {
        'userId': 'user-1',
        'subscriptionStatus': 'trial',
        'planId': 'starter',
        'cycle': 'monthly',
        'rooms': 3,
        'trialEndsAt': '2026-05-01T00:00:00.000Z',
        'nextChargeAt': '2026-06-01T00:00:00.000Z',
        'activatedAt': '2026-04-01T00:00:00.000Z',
        'user': {
          'id': 'user-1',
          'name': 'Nguyễn Văn A',
          'phone': '0912345678',
          'email': 'owner@example.com',
        },
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.userId, 'user-1');
      expect(snapshot.userName, 'Nguyễn Văn A');
      expect(snapshot.userPhone, '0912345678');
      expect(snapshot.userEmail, 'owner@example.com');
      expect(snapshot.subscriptionStatus, 'trial');
      expect(snapshot.planId, 'starter');
      expect(snapshot.cycle, 'monthly');
      expect(snapshot.rooms, 3);
      expect(snapshot.trialEndsAt, isNotNull);
      expect(snapshot.nextChargeAt, isNotNull);
      expect(snapshot.activatedAt, isNotNull);
    });

    test('userId falls back to user.id when top-level userId is missing', () {
      final json = {
        'subscriptionStatus': 'active',
        'user': {'id': 'user-from-nested', 'name': 'Test', 'phone': '0900000000'},
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.userId, 'user-from-nested');
    });

    test('userId is empty string when both userId and user.id are missing', () {
      final json = {
        'subscriptionStatus': 'none',
        'user': {'name': 'Test', 'phone': '0900000000'},
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.userId, '');
    });

    test('subscriptionStatus defaults to none when missing', () {
      final json = {
        'userId': 'u-1',
        'user': {'name': 'T', 'phone': '0900000000'},
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.subscriptionStatus, 'none');
    });

    test('nullable fields are null when missing', () {
      final json = {
        'userId': 'u-2',
        'subscriptionStatus': 'none',
        'user': {'name': 'T', 'phone': '0900000000'},
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.planId, isNull);
      expect(snapshot.cycle, isNull);
      expect(snapshot.rooms, isNull);
      expect(snapshot.trialEndsAt, isNull);
      expect(snapshot.nextChargeAt, isNull);
      expect(snapshot.activatedAt, isNull);
      expect(snapshot.userEmail, isNull);
    });

    test('date fields are null when value is empty string', () {
      final json = {
        'userId': 'u-3',
        'subscriptionStatus': 'trial',
        'trialEndsAt': '',
        'user': {'name': 'T', 'phone': '0900000000'},
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.trialEndsAt, isNull);
    });

    test('date fields are null when value is invalid string', () {
      final json = {
        'userId': 'u-4',
        'subscriptionStatus': 'trial',
        'trialEndsAt': 'not-a-date',
        'user': {'name': 'T', 'phone': '0900000000'},
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.trialEndsAt, isNull);
    });

    test('user map defaults to empty map when user key is missing', () {
      final json = {
        'userId': 'u-5',
        'subscriptionStatus': 'active',
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.userName, '');
      expect(snapshot.userPhone, '');
      expect(snapshot.userEmail, isNull);
    });

    test('rooms parses integer from num correctly', () {
      final json = {
        'userId': 'u-6',
        'subscriptionStatus': 'active',
        'rooms': 10,
        'user': {'name': 'T', 'phone': '0900000000'},
      };

      final snapshot = TrialSnapshot.fromJson(json);

      expect(snapshot.rooms, 10);
    });
  });

  group('TrialSnapshot.hasActiveTrial', () {
    test('returns true when status is trial and trialEndsAt is in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'trial',
        trialEndsAt: futureDate,
      );

      expect(snapshot.hasActiveTrial, true);
    });

    test('returns true when status is trial and trialEndsAt is null', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'trial',
        trialEndsAt: null,
      );

      expect(snapshot.hasActiveTrial, true);
    });

    test('returns false when status is trial but trialEndsAt is in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'trial',
        trialEndsAt: pastDate,
      );

      expect(snapshot.hasActiveTrial, false);
    });

    test('returns false when status is active', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'active',
      );

      expect(snapshot.hasActiveTrial, false);
    });

    test('returns false when status is none', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'none',
      );

      expect(snapshot.hasActiveTrial, false);
    });
  });

  group('TrialSnapshot.isActive', () {
    test('returns true when subscriptionStatus is active', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'active',
      );

      expect(snapshot.isActive, true);
    });

    test('returns false when subscriptionStatus is trial', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'trial',
      );

      expect(snapshot.isActive, false);
    });

    test('returns false when subscriptionStatus is none', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'none',
      );

      expect(snapshot.isActive, false);
    });

    test('returns false when subscriptionStatus is cancelled', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'cancelled',
      );

      expect(snapshot.isActive, false);
    });
  });

  group('TrialSnapshot.hasPlan', () {
    test('returns true when planId is non-null and non-empty', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'active',
        planId: 'professional',
      );

      expect(snapshot.hasPlan, true);
    });

    test('returns false when planId is null', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'active',
      );

      expect(snapshot.hasPlan, false);
    });

    test('returns false when planId is empty string', () {
      final snapshot = TrialSnapshot(
        userId: 'u',
        userName: 'T',
        userPhone: '0900000000',
        subscriptionStatus: 'active',
        planId: '',
      );

      expect(snapshot.hasPlan, false);
    });
  });

  group('TrialActionResult.fromJson', () {
    test('parses all fields correctly when all present', () {
      final json = {
        'userId': 'user-1',
        'action': 'granted',
        'days': 7,
        'planId': 'starter',
        'cycle': 'monthly',
        'rooms': 3,
        'trialEndsAt': '2026-05-01T00:00:00.000Z',
      };

      final result = TrialActionResult.fromJson(json);

      expect(result.userId, 'user-1');
      expect(result.action, 'granted');
      expect(result.days, 7);
      expect(result.planId, 'starter');
      expect(result.cycle, 'monthly');
      expect(result.rooms, 3);
      expect(result.trialEndsAt, isNotNull);
    });

    test('userId defaults to empty string when missing', () {
      final json = {
        'action': 'revoked',
      };

      final result = TrialActionResult.fromJson(json);

      expect(result.userId, '');
    });

    test('action defaults to empty string when missing', () {
      final json = {
        'userId': 'u-1',
      };

      final result = TrialActionResult.fromJson(json);

      expect(result.action, '');
    });

    test('nullable fields are null when missing', () {
      final json = {
        'userId': 'u-2',
        'action': 'extended',
      };

      final result = TrialActionResult.fromJson(json);

      expect(result.days, isNull);
      expect(result.planId, isNull);
      expect(result.cycle, isNull);
      expect(result.rooms, isNull);
      expect(result.trialEndsAt, isNull);
    });

    test('trialEndsAt is null when value is invalid date string', () {
      final json = {
        'userId': 'u-3',
        'action': 'granted',
        'trialEndsAt': 'bad-date',
      };

      final result = TrialActionResult.fromJson(json);

      expect(result.trialEndsAt, isNull);
    });

    test('parses action revoked correctly', () {
      final json = {
        'userId': 'u-4',
        'action': 'revoked',
      };

      final result = TrialActionResult.fromJson(json);

      expect(result.action, 'revoked');
    });
  });
}
