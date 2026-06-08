import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_color_scheme.dart';

class DatePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  const DatePickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? colors.brand.withValues(alpha: 0.08)
              : colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? colors.brand : colors.borderDefault,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: hasValue ? colors.brand : colors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasValue ? colors.textPrimary : colors.textTertiary,
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
}
