import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../data/models/payment_history_item.dart';
import '../../data/models/payment_quote.dart';
import '../../data/models/plan.dart';
import '../../data/models/verify_enums.dart';
import '../../utils/billing_quote_helper.dart';
import 'verify_format.dart';

/// Order summary — hiển thị `breakdown` từ BE (quote / session).
class OrderSummaryCard extends StatelessWidget {
  final Plan plan;
  final BillingCycle cycle;
  final PaymentBreakdown breakdown;
  final PaymentHistoryKind? kind;
  final int totalAmount;
  final UserModel? user;
  final bool hasPendingPaymentSession;

  const OrderSummaryCard({
    super.key,
    required this.plan,
    required this.cycle,
    required this.breakdown,
    required this.totalAmount,
    this.kind,
    this.user,
    this.hasPendingPaymentSession = false,
  });

  factory OrderSummaryCard.fromQuote({
    required Plan plan,
    required PaymentQuote quote,
    UserModel? user,
    bool hasPendingPaymentSession = false,
  }) =>
      OrderSummaryCard(
        plan: plan,
        cycle: quote.cycle,
        breakdown: quote.breakdown,
        totalAmount: quote.totalAmount,
        kind: quote.kind,
        user: user,
        hasPendingPaymentSession: hasPendingPaymentSession,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isYearly = cycle == BillingCycle.yearly;
    final periodLabel = isYearly ? '12 tháng' : '1 tháng';
    final showTrialBadge = kind == PaymentHistoryKind.subscription;
    final quote = PaymentQuote(
      kind: kind ?? PaymentHistoryKind.subscription,
      planId: plan.id,
      cycle: cycle,
      rooms: plan.rooms > 0 ? plan.rooms : 1,
      totalAmount: totalAmount,
      breakdown: breakdown,
    );
    final renewNote = BillingQuoteHelper.renewStackNote(
      quote: quote,
      user: user,
      hasPendingPaymentSession: hasPendingPaymentSession,
    );
    final upgradeNote = BillingQuoteHelper.upgradeCreditNote(
      breakdown: breakdown,
      user: user,
    );
    final cycleNote = BillingQuoteHelper.cycleDeferNote(
      quote: quote,
      user: user,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasPendingPaymentSession ? 'ĐƠN ĐÃ TẠO' : 'CHI TIẾT ĐƠN HÀNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          if (kind != null) ...[
            const SizedBox(height: 6),
            Text(
              kind!.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: colors.brandLight,
              ),
            ),
          ],
          if (kind == PaymentHistoryKind.renew) ...[
            const SizedBox(height: 8),
            _infoChip(
              context,
              icon: Icons.add_circle_outline,
              text: 'Cộng dồn vào kỳ hiện tại',
              color: colors.success,
            ),
          ],
          const SizedBox(height: 12),
          _line(
            context,
            label: '${plan.tier.displayName} × $periodLabel',
            value: VerifyFormat.priceVND(breakdown.listPrice),
          ),
          if (breakdown.creditApplied > 0) ...[
            const SizedBox(height: 8),
            _line(
              context,
              label: breakdown.remainingDays != null &&
                      breakdown.totalDays != null
                  ? 'Trừ gói cũ (còn ${breakdown.remainingDays}/'
                      '${breakdown.totalDays} ngày)'
                  : 'Credit gói cũ',
              value: '-${VerifyFormat.priceVND(breakdown.creditApplied)}',
              valueColor: colors.success,
            ),
          ],
          if (breakdown.vat > 0) ...[
            const SizedBox(height: 8),
            _line(
              context,
              label: 'VAT 10%',
              value: '+${VerifyFormat.priceVND(breakdown.vat)}',
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                VerifyFormat.priceVND(totalAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textBrand,
                ),
              ),
            ],
          ),
          if (upgradeNote != null) ...[
            const SizedBox(height: 10),
            _footnote(context, upgradeNote),
          ],
          if (renewNote != null) ...[
            const SizedBox(height: 10),
            _footnote(context, renewNote),
          ],
          if (cycleNote != null) ...[
            const SizedBox(height: 8),
            _footnote(context, cycleNote, icon: Icons.info_outline),
          ],
          if (breakdown.periodExtension != null &&
              breakdown.periodExtension!.months > 0 &&
              kind != PaymentHistoryKind.upgrade) ...[
            const SizedBox(height: 12),
            _infoChip(
              context,
              icon: Icons.event_available,
              text: 'Gia hạn thêm ${breakdown.periodExtension!.months} tháng',
              color: colors.success,
            ),
          ],
          if (showTrialBadge) ...[
            const SizedBox(height: 12),
            _infoChip(
              context,
              icon: Icons.check_circle,
              text: '7 ngày trial · Tính từ ngày được duyệt',
              color: colors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successBgDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footnote(
    BuildContext context,
    String text, {
    IconData icon = Icons.lightbulb_outline,
  }) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: colors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _line(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
