import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/verify_enums.dart';

/// Một payment method tile (radio-style) cho Screen 5.
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border.all(
            color: isSelected ? colors.brandLight : colors.borderDefault,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? colors.brandLight : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colors.brandLight : colors.borderStrong,
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: AppColors.darkBg)
                  : null,
            ),
            const SizedBox(width: 12),
            // Logo container
            Container(
              width: 36,
              height: 28,
              decoration: BoxDecoration(
                color: colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _iconFor(method),
                size: 16,
                color: _iconColorFor(method, colors),
              ),
            ),
            const SizedBox(width: 12),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? colors.textPrimary : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.vnpayQR:
        return Icons.qr_code_2;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.card:
        return Icons.credit_card;
    }
  }

  Color _iconColorFor(PaymentMethod m, AppColorScheme colors) {
    switch (m) {
      case PaymentMethod.vnpayQR:
        return colors.brandLight;
      case PaymentMethod.bankTransfer:
        return colors.brandSecondary;
      case PaymentMethod.card:
        return colors.brandWarm;
    }
  }
}
