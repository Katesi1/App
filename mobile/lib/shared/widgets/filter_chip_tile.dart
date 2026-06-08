import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_color_scheme.dart';

class FilterChipTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipTile({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.brand.withValues(alpha: 0.08)
              : colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.brand : colors.borderDefault,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.brand : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? colors.brand : colors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded, size: 14, color: colors.brand),
            ],
          ],
        ),
      ),
    );
  }
}
