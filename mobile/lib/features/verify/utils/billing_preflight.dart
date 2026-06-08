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

/// `GET /payments/active` — BE chỉ trả session `pending`.
Future<PaymentSession?> fetchActivePendingSession(WidgetRef ref) async {
  final notifier = ref.read(verifyFlowControllerProvider.notifier);
  try {
    return await notifier.syncActivePaymentFromApi();
  } on VerifyApiException {
    rethrow;
  } catch (_) {
    return null;
  }
}

/// Hydrate verify state từ session pending (plan + quote + session).
Future<void> hydratePendingSession(WidgetRef ref, PaymentSession session) async {
  List<Plan> plans;
  try {
    plans = await ref.read(verifyPlansProvider.future);
  } catch (_) {
    plans = const [];
  }

  final plan = _planForSession(session, plans);
  if (plan == null) return;

  final cycle = session.cycle ?? BillingCycle.monthly;
  final quote = _quoteFromSession(session, plan, cycle);
  ref.read(verifyFlowControllerProvider.notifier).hydrateFromActiveSession(
        session: session,
        plan: plan,
        cycle: cycle,
        quote: quote,
      );
}

/// Pre-flight: có session pending → hydrate + mở màn thanh toán (không chọn gói).
Future<bool> redirectToPendingPaymentIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  PaymentSession? session;
  try {
    session = await fetchActivePendingSession(ref);
  } on VerifyApiException catch (e) {
    if (context.mounted) showPaymentApiError(context, e, ref: ref);
    return false;
  }

  if (session == null || !context.mounted) return false;

  await hydratePendingSession(ref, session);
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
    final tier = Plan.tierFromPlanId(planId);
    if (tier != null) {
      return Plan(
        id: planId,
        tier: tier,
        rooms: tier.rooms,
        monthlyPrice: 0,
        features: const [],
      );
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
