import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/homestay_model.dart';

/// Card quản lý phòng (dùng HomestayModel) — có nút edit
class PropertyManagementCard extends StatelessWidget {
  final HomestayModel homestay;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const PropertyManagementCard({
    super.key,
    required this.homestay,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: homestay.isActive ? 1.0 : 0.55,
      child: Material(
      color: isDark ? AppColors.darkContainer : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Icon ──
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.oceanLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _iconForName(homestay.name),
                  color: AppColors.ocean,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homestay.name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            homestay.address,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: homestay.isActive
                                ? AppColors.emeraldLight
                                : AppColors.slateLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            homestay.isActive ? 'Hoạt động' : 'Tạm nghỉ',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: homestay.isActive
                                  ? AppColors.greenForest
                                  : AppColors.slate,
                            ),
                          ),
                        ),
                        if (homestay.roomCount != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${homestay.roomCount} phòng',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Edit button ──
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ocean.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.ocean,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  IconData _iconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('villa')) return Icons.villa_rounded;
    if (lower.contains('hotel') || lower.contains('khách sạn')) {
      return Icons.hotel_rounded;
    }
    return Icons.cottage_rounded;
  }
}
