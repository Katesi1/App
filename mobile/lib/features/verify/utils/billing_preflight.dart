import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_history_item.dart';
import '../data/models/payment_quote.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import 'payment_error_handler.dart';

/// Pre-flight billing: `GET /payments/active` trước màn chọn gói.
///
/// Nếu có session `pending` → hydrate state + điều hướng thẳng màn QR/thanh toán.
/// Trả `true` nếu đã redirect (caller không render select-plan).
Future<bool> redirectToPendingPaymentIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final notifier = ref.read(verifyFlowControllerProvider.notifier);

  PaymentSession? session;
  try {
    session = await notifier.syncActivePaymentFromApi();
  } on VerifyApiException catch (e) {
    if (context.mounted) showPaymentApiError(context, e, ref: ref);
    return false;
  }

  if (session == null || !context.mounted) return false;

  try {
    final status = await notifier.checkPaymentStatus();
    if (!context.mounted || status != PaymentStatus.pending) return false;
  } catch (_) {
    return false;
  }

  final plans = await ref.read(verifyPlansProvider.future);
  final plan = _planForSession(session, plans);
  if (plan == null || !context.mounted) return false;

  final cycle = session.cycle ?? BillingCycle.monthly;
  final quote = _quoteFromSession(session, plan, cycle);
  notifier.hydrateFromActiveSession(
    session: session,
    plan: plan,
    cycle: cycle,
    quote: quote,
  );

  if (!context.mounted) return true;
  context.replace('/verify/payment');
  return true;
}

Plan? _planForSession(PaymentSession session, List<Plan> plans) {
  final planId = session.planId;
  if (planId != null && planId.isNotEmpty) {
    for (final p in plans) {
      if (p.id == planId) return p;
    }
  }
  return plans.isNotEmpty ? plans.first : null;
}

PaymentQuote _quoteFromSession(
  PaymentSession session,
  Plan plan,
  BillingCycle cycle,
) {
  final breakdown = session.breakdown ??
      PaymentBreakdown(
        listPrice: session.totalAmount,
        creditApplied: 0,
        vat: 0,
      );
  return PaymentQuote(
    kind: session.kind ?? PaymentHistoryKind.subscription,
    planId: session.planId ?? plan.id,
    cycle: cycle,
    rooms: plan.rooms > 0 ? plan.rooms : 1,
    totalAmount: session.totalAmount,
    breakdown: breakdown,
  );
}
