import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_color_scheme.dart';

/// Badge đánh giá dùng chung: "⭐ 4.9 · 37 đánh giá".
///
/// - Caller tự ẩn khi chưa có review (`room.hasRating == false`) — badge
///   không tự kiểm tra để giữ nó thuần trình bày.
/// - [onImage] = true: kiểu overlay tối, đặt đè lên ảnh (card). false: kiểu
///   inline theo theme, dùng trong nội dung (chi tiết).
/// - [showCount] = false: chỉ hiện sao + điểm (chỗ hẹp).
class RatingBadge extends StatelessWidget {
  final double ratingAvg;
  final int reviewCount;
  final bool onImage;
  final bool showCount;

  const RatingBadge({
    super.key,
    required this.ratingAvg,
    required this.reviewCount,
    this.onImage = false,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final starColor = onImage ? const Color(0xFFFFC53D) : colors.warning;
    final textColor = onImage ? Colors.white : colors.textPrimary;
    final subColor =
        onImage ? Colors.white.withValues(alpha: 0.85) : colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: 0.55)
            : colors.warningBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: starColor),
          const SizedBox(width: 3),
          Text(
            ratingAvg.toStringAsFixed(1),
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (showCount) ...[
            Text(
              ' · $reviewCount đánh giá',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
