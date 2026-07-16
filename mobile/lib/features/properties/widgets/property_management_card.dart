import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/homestay_model.dart';
import '../../../shared/widgets/owner_info_tile.dart';

/// Card quản lý phòng (dùng HomestayModel) — có nút edit
class PropertyManagementCard extends StatelessWidget {
  final HomestayModel homestay;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  /// Hiện thông tin chủ sở hữu (chỉ ADMIN / SALE hệ thống).
  final bool showOwner;

  const PropertyManagementCard({
    super.key,
    required this.homestay,
    this.onTap,
    this.onEdit,
    this.showOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: homestay.isActive ? 1.0 : 0.55,
      child: Material(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
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
                    color: colors.brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _iconForName(homestay.name),
                    color: colors.brand,
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
                        homestay.code.isNotEmpty
                            ? '${homestay.code} · ${homestay.name}'
                            : homestay.name,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              homestay.address,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: colors.textSecondary,
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
                                  ? colors.successBg
                                  : colors.bgSurfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              homestay.isActive ? 'Hoạt động' : 'Tạm nghỉ',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: homestay.isActive
                                    ? colors.success
                                    : colors.textTertiary,
                              ),
                            ),
                          ),
                          if (homestay.roomCount != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${homestay.roomCount} phòng',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (showOwner) ...[
                        const SizedBox(height: 8),
                        OwnerInfoTile(
                          name: homestay.ownerName,
                          phone: homestay.ownerPhone,
                          dense: true,
                        ),
                      ],
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
                        color: colors.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: colors.brand,
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
