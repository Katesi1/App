import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.oceanPale : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.ocean : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.ocean : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.ocean : AppColors.ink,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, size: 14, color: AppColors.ocean),
            ],
          ],
        ),
      ),
    );
  }
}
