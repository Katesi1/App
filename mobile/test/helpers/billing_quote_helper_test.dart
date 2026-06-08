import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/features/verify/data/models/payment_history_item.dart';
import 'package:mobile/features/verify/data/models/payment_quote.dart';
import 'package:mobile/features/verify/data/models/verify_enums.dart';
import 'package:mobile/features/verify/utils/billing_quote_helper.dart';

void main() {
  group('BillingQuoteHelper', () {
    test('projectedPeriodEnd stacks from currentPeriodEnd', () {
      final end = DateTime(2026, 7, 8);
      final projected = BillingQuoteHelper.projectedPeriodEnd(
        currentPeriodEnd: end,
        newCycle: BillingCycle.yearly,
      );
      expect(projected, end.add(const Duration(days: 365)));
    });

    test('upgradeCreditNote shows remaining/total days', () {
      const breakdown = PaymentBreakdown(
        listPrice: 5000000,
        creditApplied: 132667,
        vat: 0,
        remainingDays: 20,
        totalDays: 30,
        currentPlanId: 'rooms_1',
      );
      final note = BillingQuoteHelper.upgradeCreditNote(
        breakdown: breakdown,
        user: null,
      );
      expect(note, contains('20/30'));
      expect(note, contains('Mini'));
    });

    test('renewStackNote warns when pending session', () {
      final quote = PaymentQuote(
        kind: PaymentHistoryKind.renew,
        planId: 'rooms_1',
        cycle: BillingCycle.monthly,
        rooms: 1,
        totalAmount: 199000,
        breakdown: const PaymentBreakdown(
          listPrice: 199000,
          creditApplied: 0,
          vat: 0,
        ),
      );
      final note = BillingQuoteHelper.renewStackNote(
        quote: quote,
        user: UserModel(
          id: 'u1',
          name: 'Owner',
          phone: '0900000000',
          role: 1,
          currentPeriodEnd: DateTime(2026, 7, 8),
        ),
        hasPendingPaymentSession: true,
      );
      expect(note, contains('admin duyệt'));
      expect(note, contains('hạn kỳ cũ'));
    });
  });
}
