import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';

/// Room card matching HTML design screen 04:
/// - Image area with gradient bg + status badge top-right
/// - Name row: "P.101 · Standard" + price right-aligned
/// - Subtitle: floor · capacity · area
/// - Amenity chips row
class RoomCard extends StatefulWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final int animationIndex;

  /// Chỉ tab đang visible mới bật Hero — tránh trùng tag khi TabBarView
  /// keep-alive nhiều tab cùng chứa một phòng.
  final bool enableHero;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.animationIndex = 0,
    this.enableHero = true,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final room = widget.room;
    final statusColor = room.isActive ? colors.success : colors.textTertiary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ────────────────────────────────────────
              Stack(
                children: [
                  _buildCoverImage(context, room),
                  // Status badge top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        room.isActive ? 'Hoạt động' : 'Tạm nghỉ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Body info ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${room.code} · ${room.name}',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _buildSubtitle(room),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          room.priceDisplay,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textBrand,
                          ),
                        ),
                      ],
                    ),

                    // Amenity chips
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _buildAmenityChips(context, room),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.animationIndex * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }

  String _buildSubtitle(RoomModel room) {
    final parts = <String>[];
    if (room.homestay != null) {
      parts.add(room.homestay!.name);
    }
    // Phòng ngủ
    parts.add(room.bedrooms == 0 ? 'Studio' : '${room.bedrooms}PN');
    // WC
    if (room.bathrooms > 0) {
      parts.add('${room.bathrooms}WC');
    }
    // Sức chứa
    parts.add('${room.standardGuests} người');
    return parts.join(' · ');
  }

  List<Widget> _buildAmenityChips(BuildContext context, RoomModel room) {
    if (room.amenities.isEmpty) return [];
    final colors = context.colors;
    return room.amenities
        .take(3)
        .map((label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ))
        .toList();
  }

  Widget _buildCoverImage(BuildContext context, RoomModel room) {
    final image = SizedBox(
      height: 120,
      width: double.infinity,
      child: room.coverImageUrl != null
          ? CachedNetworkImage(
              imageUrl: room.coverImageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 400,
              placeholder: (_, __) => _imagePlaceholder(context),
              errorWidget: (_, __, ___) => _imagePlaceholder(context),
            )
          : _imagePlaceholder(context),
    );

    if (!widget.enableHero) return image;

    return Hero(
      tag: 'room-cover-${room.id}',
      child: image,
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
      ),
      child: Center(
        child: Icon(Icons.home_rounded,
            size: 36, color: colors.brand.withValues(alpha: 0.5)),
      ),
    );
  }
}
