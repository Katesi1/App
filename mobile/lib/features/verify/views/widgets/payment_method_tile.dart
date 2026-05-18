import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/verify_enums.dart';

/// A single payment-method tile (radio-style) for Screen 5.
///
/// `isComingSoon` = true → tile dims, taps disabled, shows the "Coming soon"
/// badge (used for credit card — card gateway not integrated yet).
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final bool isComingSoon;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = isComingSoon;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border.all(
              color: isSelected && !disabled
                  ? colors.brandLight
                  : colors.borderDefault,
              width: isSelected && !disabled ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected && !disabled
                      ? colors.brandLight
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected && !disabled
                        ? colors.brandLight
                        : colors.borderStrong,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isSelected && !disabled
                    ? Icon(Icons.check, size: 12, color: AppColors.darkBg)
                    : null,
              ),
              const SizedBox(width: 12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            method.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected && !disabled
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                        if (disabled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bgSurfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.borderDefault),
                            ),
                            child: Text(
                              'Đang phát triển',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      disabled
                          ? 'Tính năng sẽ ra mắt trong bản cập nhật tới'
                          : method.subtitle,
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
