import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_color_scheme.dart';

class GuestCounter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const GuestCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: value > 0 ? () => onChanged(value - 1) : null,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: value > 0 ? colors.brand : colors.borderDefault,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(value + 1),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
