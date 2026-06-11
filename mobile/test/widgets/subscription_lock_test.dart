import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/widgets/subscription_locked_sheet.dart';

void main() {
  group('SubscriptionLock.isLocked', () {
    test('detects by BE code (subscription.featureLocked)', () {
      expect(
        SubscriptionLock.isLocked(code: 'subscription.featureLocked'),
        isTrue,
      );
    });

    test('code match is case-insensitive', () {
      expect(SubscriptionLock.isLocked(code: 'Subscription.FeatureLocked'),
          isTrue);
    });

    test('detects by Vietnamese message fallback', () {
      expect(
        SubscriptionLock.isLocked(
          message: 'Tài khoản chưa có quyền dùng tính năng này.',
        ),
        isTrue,
      );
    });

    test('detects by English message fallback', () {
      expect(
        SubscriptionLock.isLocked(
          message: 'Your account is not authorized to use this feature.',
        ),
        isTrue,
      );
    });

    test('does not match unrelated errors', () {
      expect(SubscriptionLock.isLocked(code: 'paymentPending'), isFalse);
      expect(
        SubscriptionLock.isLocked(message: 'Lỗi kết nối, vui lòng thử lại'),
        isFalse,
      );
    });

    test('returns false when both null', () {
      expect(SubscriptionLock.isLocked(), isFalse);
    });

    test('code takes precedence even with an unrelated message', () {
      expect(
        SubscriptionLock.isLocked(
          code: 'subscription.featureLocked',
          message: 'bất kỳ',
        ),
        isTrue,
      );
    });
  });
}
