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
            // ── Image gallery header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _ImageGalleryHeader(room: room, roomId: roomId),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title + Status ───────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: GoogleFonts.nunito(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (room.homestay != null)
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        size: 16,
                                        color: colors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${room.homestay!.name} · ${room.homestay!.address}',
                                        style: GoogleFonts.nunito(
                                          color: colors.onSurface
                                              .withValues(alpha: 0.55),
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    AppRadius.full),
                                border: Border.all(
                                  color: colors.primary
                                      .withValues(alpha: 0.3),
                                ),
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
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: room.isActive
                                    ? AppColors.success
                                        .withValues(alpha: 0.1)
                                    : colors.outline
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    AppRadius.full),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: room.isActive
                                          ? AppColors.success
                                          : colors.outline,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    room.isActive
                                        ? 'Hoạt động'
                                        : 'Tạm nghỉ',
                                    style: GoogleFonts.nunito(
                                      color: room.isActive
                                          ? AppColors.success
                                          : colors.outline,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.08, end: 0),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Quick info cards ─────────────────────────────────
                    Row(
                      children: [
                        _QuickInfo(
                          icon: Icons.people_outline_rounded,
                          value: '${room.maxGuests}',
                          label: 'Khách tối đa',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _QuickInfo(
                          icon: Icons.bed_outlined,
                          value: '${room.bedrooms}',
                          label: 'Phòng ngủ',
                          color: AppColors.secondary,
                        ),
                        if (room.price != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _QuickInfo(
                            icon: Icons.photo_library_outlined,
                            value: '${room.images.length}',
                            label: 'Hình ảnh',
                            color: AppColors.info,
                          ),
                        ],
                      ],
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.08, end: 0),

                    // ── Price section ────────────────────────────────────
                    if (room.price != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Icon(Icons.sell_rounded,
                              size: 20, color: colors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Bảng giá',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (user?.canEdit == true)
                            TextButton.icon(
                              onPressed: () => context
                                  .push('/rooms/$roomId/price'),
                              icon: const Icon(Icons.edit_rounded,
                                  size: 16),
                              label: Text(
                                'Sửa giá',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PriceGrid(price: room.price!),
                    ]
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.08, end: 0),

                    // ── Description ──────────────────────────────────────
                    if (room.description?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 20, color: colors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Mô tả',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          room.description!,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            height: 1.7,
                            color: colors.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],

                    // ── Gallery thumbnails ───────────────────────────────
                    if (room.images.length > 1) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Icon(Icons.photo_library_rounded,
                              size: 20, color: colors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Hình ảnh (${room.images.length})',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (user?.canEdit == true)
                            TextButton.icon(
                              onPressed: () => context
                                  .push('/rooms/$roomId/images'),
                              icon: const Icon(Icons.settings_rounded,
                                  size: 16),
                              label: Text(
                                'Quản lý',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: room.images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () =>
                                _openGallery(context, room, i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppRadius.md),
                              child: CachedNetworkImage(
                                imageUrl: room.images[i].imageUrl,
                                width: 130,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                              .animate(
                                  delay: Duration(
                                      milliseconds: i * 60))
                              .fadeIn(duration: 300.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                              ),
                        ),
                      ),
                    ],

                    // ── Management buttons ───────────────────────────────
                    if (user?.canEdit == true) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding:
                            const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: colors.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.settings_rounded,
                                    size: 18,
                                    color: colors.primary),
                                const SizedBox(
                                    width: AppSpacing.sm),
                                Text(
                                  'Quản lý phòng',
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _MgmtButton(
                                    icon: Icons
                                        .edit_rounded,
                                    label: 'Sửa phòng',
                                    onTap: () => context.push(
                                        '/rooms/$roomId/edit'),
                                  ),
                                ),
                                const SizedBox(
                                    width: AppSpacing.sm),
                                Expanded(
                                  child: _MgmtButton(
                                    icon: Icons
                                        .photo_library_outlined,
                                    label: 'Quản lý ảnh',
                                    onTap: () => context.push(
                                        '/rooms/$roomId/images'),
                                  ),
                                ),
                                const SizedBox(
                                    width: AppSpacing.sm),
                                Expanded(
                                  child: _MgmtButton(
                                    icon: Icons
                                        .price_change_outlined,
                                    label: 'Cập nhật giá',
                                    onTap: () => context.push(
                                        '/rooms/$roomId/price'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Bottom booking bar ───────────────────────────────────────────
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md),
              child: Row(
                children: [
                  // Price column
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá từ',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: colors.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          room.priceDisplay,
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Calendar button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colors.primary,
                        width: 1.5,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                    ),
                    child: IconButton(
                      onPressed: () =>
                          context.push('/rooms/$roomId/calendar'),
                      icon: Icon(Icons.calendar_month_rounded,
                          color: colors.primary),
                      tooltip: 'Xem lịch',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Book now button
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          context.push('/rooms/$roomId/hold'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        'Đặt ngay',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openGallery(
      BuildContext context, RoomModel room, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GalleryScreen(
            images: room.images, initialIndex: initialIndex),
      ),
    );
  }
}

// ─── Image Gallery Header with PageView + Dots ───────────────────────────────
class _ImageGalleryHeader extends StatefulWidget {
  final RoomModel room;
  final String roomId;
  const _ImageGalleryHeader(
      {required this.room, required this.roomId});

  @override
  State<_ImageGalleryHeader> createState() =>
      _ImageGalleryHeaderState();
}

class _ImageGalleryHeaderState extends State<_ImageGalleryHeader> {
  int _currentPage = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final colors = Theme.of(context).colorScheme;
    final images = room.images;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Image gallery
        SizedBox(
          height: 320,
          child: images.isNotEmpty
              ? PageView.builder(
                  controller: _pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) =>
                      setState(() => _currentPage = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _GalleryScreen(
                            images: images, initialIndex: i),
                      ),
                    ),
                    child: Hero(
                      tag: i == 0
                          ? 'room-cover-${room.id}'
                          : 'room-img-${room.id}-$i',
                      child: CachedNetworkImage(
                        imageUrl: images[i].imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 320,
                        placeholder: (_, __) => Container(
                          color: colors.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: colors.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 60,
                              color: colors.onSurface
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  color: colors.surfaceContainerHighest,
                  child: Center(
                    child: Icon(Icons.image_outlined,
                        size: 80,
                        color: colors.onSurface
                            .withValues(alpha: 0.2)),
                  ),
                ),
        ),

        // Gradient overlay top (for back button visibility)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topPadding + 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Back + Share buttons
        Positioned(
          top: topPadding + 8,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.share_rounded,
                    onTap: () {
                      final text =
                          '🏠 ${room.name} (${room.code})\n'
                          '📍 ${room.homestay?.address ?? ''}\n'
                          '👥 Tối đa: ${room.maxGuests} khách | '
                          '${room.bedrooms} phòng ngủ\n'
                          '💰 Giá từ: ${room.priceDisplay}';
                      Share.share(text);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Dot indicators
        if (images.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            ),
          ),

        // Image counter badge
        if (images.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius:
                    BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${_currentPage + 1}/${images.length}',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Circle icon button overlay ──────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─── Quick info card ─────────────────────────────────────────────────────────
class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickInfo({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Price Grid ──────────────────────────────────────────────────────────────
class _PriceGrid extends StatelessWidget {
  final RoomPriceModel price;
  const _PriceGrid({required this.price});

  String _fmt(double p) {
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}tr';
    return '${(p / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _priceItem(
                'Ngày thường',
                price.weekdayPrice,
                Icons.wb_sunny_outlined,
                const Color(0xFF1976D2),
              ),
              const SizedBox(width: AppSpacing.md),
              _priceItem(
                'Thứ 6',
                price.fridayPrice,
                Icons.weekend_outlined,
                const Color(0xFF7B1FA2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _priceItem(
                'Thứ 7',
                price.saturdayPrice,
                Icons.star_outline_rounded,
                const Color(0xFFE65100),
              ),
              const SizedBox(width: AppSpacing.md),
              _priceItem(
                'Lễ / Tết',
                price.holidayPrice,
                Icons.celebration_outlined,
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceItem(
      String label, double amount, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
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
                  '${_fmt(amount)}đ',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Management Button ───────────────────────────────────────────────────────
class _MgmtButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MgmtButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: colors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gallery Screen ──────────────────────────────────────────────────────────
class _GalleryScreen extends StatelessWidget {
  final List<RoomImageModel> images;
  final int initialIndex;

  const _GalleryScreen(
      {required this.images, required this.initialIndex});

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
          pageController:
              PageController(initialPage: initialIndex),
          builder: (_, i) => PhotoViewGalleryPageOptions(
            imageProvider:
                CachedNetworkImageProvider(images[i].imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
          backgroundDecoration:
              const BoxDecoration(color: Colors.black),
        ),
      );
}
