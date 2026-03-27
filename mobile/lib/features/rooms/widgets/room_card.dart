import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
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

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.animationIndex = 0,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Hero(
                    tag: 'room-cover-${room.id}',
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: room.coverImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: room.coverImageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 400,
                              placeholder: (_, __) =>
                                  _imagePlaceholder(),
                              errorWidget: (_, __, ___) =>
                                  _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                    ),
                  ),
                  // Status badge top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: room.isActive
                            ? AppColors.emeraldLight
                            : AppColors.amberLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        room.isActive ? 'Trống' : 'Đang ở',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: room.isActive
                              ? AppColors.greenForest
                              : AppColors.brownDark,
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${room.code} · ${room.name}',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _buildSubtitle(room),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: AppColors.muted,
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
                            color: AppColors.ocean,
                          ),
                        ),
                      ],
                    ),

                    // Amenity chips
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _buildAmenityChips(room),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(
            delay: Duration(milliseconds: widget.animationIndex * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }

  String _buildSubtitle(RoomModel room) {
    final parts = <String>[];
    if (room.homestay != null) {
      parts.add(room.homestay!.name);
    }
    parts.add('${room.maxGuests} người');
    return parts.join(' · ');
  }

  List<Widget> _buildAmenityChips(RoomModel room) {
    final chips = <String>[];
    if (room.description?.toLowerCase().contains('view') == true ||
        room.description?.toLowerCase().contains('biển') == true) {
      chips.add('View biển');
    }
    chips.add('Điều hoà');
    if (room.bedrooms >= 2) {
      chips.add('${room.bedrooms} PN');
    }
    if (room.price != null && room.price!.weekdayPrice >= 1000000) {
      chips.add('Smart TV');
    }

    return chips
        .take(3)
        .map((label) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ))
        .toList();
  }

  Widget _imagePlaceholder() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.oceanLight,
              AppColors.tealLight,
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.home_rounded,
              size: 36, color: AppColors.oceanMid),
        ),
      );
}
