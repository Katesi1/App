import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/room_provider.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final user = ref.watch(currentUserProvider);
    final colors = Theme.of(context).colorScheme;

    return roomAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const DetailSkeleton(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phòng')),
        body: ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(roomDetailProvider(roomId)),
        ),
      ),
      data: (room) => Scaffold(
        body: CustomScrollView(
          slivers: [
            // ── Collapsible cover image ─────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: colors.surface,
              foregroundColor: colors.onSurface,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Chia sẻ',
                  onPressed: () => _share(room),
                ),
                if (user?.canEdit == true)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Chỉnh sửa',
                    onPressed: () => context.push('/rooms/$roomId/edit'),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _CoverImage(room: room),
                collapseMode: CollapseMode.parallax,
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title row ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                border: Border.all(
                                    color:
                                        colors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                room.code,
                                style: GoogleFonts.nunito(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 3),
                              decoration: BoxDecoration(
                                color: room.isActive
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : colors.outline.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                room.isActive ? 'Hoạt động' : 'Tạm nghỉ',
                                style: GoogleFonts.nunito(
                                  color: room.isActive
                                      ? AppColors.success
                                      : colors.outline,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    // ── Location ──────────────────────────────────────
                    if (room.homestay != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 16, color: colors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.homestay!.name,
                                  style: GoogleFonts.nunito(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  room.homestay!.address,
                                  style: GoogleFonts.nunito(
                                    color: colors.onSurface
                                        .withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate(delay: 50.ms).fadeIn(duration: 300.ms),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // ── Stat cards ────────────────────────────────────
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.people_outline_rounded,
                          value: '${room.maxGuests}',
                          label: 'Khách tối đa',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatCard(
                          icon: Icons.bed_outlined,
                          value: '${room.bedrooms}',
                          label: 'Phòng ngủ',
                          color: AppColors.secondary,
                        ),
                        if (room.price != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _StatCard(
                            icon: Icons.monetization_on_outlined,
                            value: room.priceDisplay,
                            label: 'Giá từ',
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    // ── Price table ───────────────────────────────────
                    if (room.price != null)
                      ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Bảng giá',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _PriceCard(
                              label: 'Thường',
                              price: room.price!.weekdayPrice,
                              color: const Color(0xFF1976D2),
                              icon: Icons.wb_sunny_outlined,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _PriceCard(
                              label: 'Thứ 6',
                              price: room.price!.fridayPrice,
                              color: const Color(0xFF7B1FA2),
                              icon: Icons.weekend_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _PriceCard(
                              label: 'Thứ 7',
                              price: room.price!.saturdayPrice,
                              color: const Color(0xFFE65100),
                              icon: Icons.star_outline_rounded,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _PriceCard(
                              label: 'Lễ / Tết',
                              price: room.price!.holidayPrice,
                              color: AppColors.error,
                              icon: Icons.celebration_outlined,
                            ),
                          ],
                        ),
                      ]
                          .animate(delay: 150.ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1, end: 0),

                    // ── Description ───────────────────────────────────
                    if (room.description?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Mô tả',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        room.description!,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          height: 1.6,
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],

                    // ── Gallery thumbnails ────────────────────────────
                    if (room.images.length > 1) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Hình ảnh (${room.images.length})',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: room.images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _openGallery(context, room, i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: CachedNetworkImage(
                                imageUrl: room.images[i].imageUrl,
                                width: 110,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                              .animate(delay: Duration(milliseconds: i * 60))
                              .fadeIn(duration: 300.ms),
                        ),
                      ),
                    ],

                    // ── Management buttons ────────────────────────────
                    if (user?.canEdit == true) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Quản lý',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/rooms/$roomId/images'),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Quản lý ảnh'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/rooms/$roomId/price'),
                              icon: const Icon(Icons.price_change_outlined),
                              label: const Text('Cập nhật giá'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Bottom action bar ───────────────────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/rooms/$roomId/calendar'),
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(
                      'Xem lịch',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/rooms/$roomId/hold'),
                    icon: const Icon(Icons.lock_clock_rounded),
                    label: Text(
                      'Giữ phòng',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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

  void _openGallery(BuildContext context, RoomModel room, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _GalleryScreen(images: room.images, initialIndex: initialIndex),
      ),
    );
  }

  void _share(RoomModel room) {
    final text =
        '🏠 ${room.name} (${room.code})\n📍 ${room.homestay?.address ?? ''}\n'
        '👥 Tối đa: ${room.maxGuests} khách | ${room.bedrooms} phòng ngủ\n'
        '💰 Giá từ: ${room.priceDisplay}';
    Share.share(text);
  }
}

// ─── Cover image with Hero ────────────────────────────────────────────────────
class _CoverImage extends StatelessWidget {
  final RoomModel room;
  const _CoverImage({required this.room});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (room.coverImageUrl == null) {
      return Container(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.image_outlined,
              size: 80, color: colors.onSurface.withValues(alpha: 0.2)),
        ),
      );
    }
    return Hero(
      tag: 'room-cover-${room.id}',
      child: CachedNetworkImage(
        imageUrl: room.coverImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(
          color: colors.surfaceContainerHighest,
        ),
        errorWidget: (_, __, ___) => Container(
          color: colors.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.broken_image_outlined,
                size: 60, color: colors.onSurface.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Price Card ───────────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final String label;
  final double price;
  final Color color;
  final IconData icon;

  const _PriceCard({
    required this.label,
    required this.price,
    required this.color,
    required this.icon,
  });

  String _fmt(double p) {
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}tr';
    return '${(p / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_fmt(price)}đ',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
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

// ─── Gallery Screen ───────────────────────────────────────────────────────────
class _GalleryScreen extends StatelessWidget {
  final List<RoomImageModel> images;
  final int initialIndex;

  const _GalleryScreen({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${images.length} ảnh',
              style: GoogleFonts.nunito(color: Colors.white)),
        ),
        body: PhotoViewGallery.builder(
          itemCount: images.length,
          pageController: PageController(initialPage: initialIndex),
          builder: (_, i) => PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(images[i].imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      );
}
