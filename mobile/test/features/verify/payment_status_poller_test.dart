import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/verify/utils/payment_status_poller.dart';

void main() {
  group('PaymentStatusPoller.intervalForElapsed', () {
    test('polls every 5s in first 5 minutes', () {
      expect(
        PaymentStatusPoller.intervalForElapsed(const Duration(minutes: 2)),
        const Duration(seconds: 5),
      );
    });

    test('polls every 15s between 5 and 30 minutes', () {
      expect(
        PaymentStatusPoller.intervalForElapsed(const Duration(minutes: 10)),
        const Duration(seconds: 15),
      );
    });

    test('polls every 60s after 30 minutes', () {
      expect(
        PaymentStatusPoller.intervalForElapsed(const Duration(hours: 2)),
        const Duration(seconds: 60),
      );
    });
  });
}
