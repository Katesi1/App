import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../data/models/payment_session.dart';
import '../../data/models/verify_enums.dart';
import 'verify_format.dart';

/// Order summary dựng từ `PaymentQuote` BE trả (`POST /payments/quote`).
/// FE KHÔNG tự tính — chỉ render breakdown (listPrice, creditApplied, vat,
/// totalAmount) + nhãn loại giao dịch.
class QuoteSummaryCard extends StatelessWidget {
  final PaymentQuote quote;
  final String planName;

  const QuoteSummaryCard({
    super.key,
    required this.quote,
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final b = quote.breakdown;
    final isUpgrade = quote.kind == TransactionKind.upgrade;
    final cycleLabel = quote.cycle == 'yearly' ? 'năm' : 'tháng';

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'CHI TIẾT ĐƠN HÀNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: colors.textTertiary,
                  ),
                ),
              ),
              if (quote.kind != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    quote.kind!.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colors.textBrand,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _line(context,
              label: '$planName · /$cycleLabel',
              value: VerifyFormat.priceVND(b.listPrice)),
          if (b.creditApplied > 0) ...[
            const SizedBox(height: 8),
            _line(
              context,
              label: isUpgrade && b.remainingDays != null && b.totalDays != null
                  ? 'Trừ gói cũ (còn ${b.remainingDays}/${b.totalDays} ngày)'
                  : 'Trừ credit gói cũ',
              value: '-${VerifyFormat.priceVND(b.creditApplied)}',
              valueColor: colors.success,
            ),
          ],
          const SizedBox(height: 8),
          _line(context,
              label: 'VAT 10%', value: '+${VerifyFormat.priceVND(b.vat)}'),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cần thanh toán',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                VerifyFormat.priceVND(quote.totalAmount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textBrand,
                ),
              ),
            ],
          ),
          if (b.periodExtensionMonths != null) ...[
            const SizedBox(height: 10),
            _note(
              context,
              icon: Icons.event_repeat_rounded,
              text: b.periodExtensionMonths == 12
                  ? 'Gia hạn thêm 1 năm cho kỳ hiện tại.'
                  : 'Gia hạn thêm ${b.periodExtensionMonths} tháng cho kỳ hiện tại.',
            ),
          ],
          if (isUpgrade) ...[
            const SizedBox(height: 10),
            _note(
              context,
              icon: Icons.upgrade_rounded,
              text:
                  'Nâng gói áp dụng ngay; giữ nguyên ngày hết hạn kỳ hiện tại.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(BuildContext context,
      {required String label, required String value, Color? valueColor}) {
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

  Widget _note(BuildContext context,
      {required IconData icon, required String text}) {
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
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
