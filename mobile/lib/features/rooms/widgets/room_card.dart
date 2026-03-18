import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';

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
    final colors = Theme.of(context).colorScheme;
    final room = widget.room;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 2,
          shadowColor: colors.shadow.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image 16:9 with price badge ──────────────────────────────
              Stack(
                children: [
                  Hero(
                    tag: 'room-cover-${room.id}',
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: room.coverImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: room.coverImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _imagePlaceholder(colors),
                              errorWidget: (_, __, ___) =>
                                  _imagePlaceholder(colors),
                            )
                          : _imagePlaceholder(colors),
                    ),
                  ),

                  // Price badge — top right
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        room.priceDisplay,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Status badge — top left
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: room.isActive
                            ? AppColors.success.withValues(alpha: 0.9)
                            : Colors.grey.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        room.isActive ? 'Hoạt động' : 'Tạm nghỉ',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Info ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + code chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                                color: colors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            room.code,
                            style: GoogleFonts.nunito(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Homestay name
                    if (room.homestay != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: colors.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              room.homestay!.name,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.55),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // Info chips
                    Row(
                      children: [
                        _infoChip(context, Icons.people_outline_rounded,
                            '${room.maxGuests} khách'),
                        const SizedBox(width: AppSpacing.sm),
                        _infoChip(context, Icons.bed_outlined,
                            '${room.bedrooms} phòng ngủ'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.animationIndex * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _imagePlaceholder(ColorScheme colors) => Container(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.image_outlined,
              size: 40, color: colors.onSurface.withValues(alpha: 0.25)),
        ),
      );

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: colors.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
