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
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/room_controller.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
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
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // ── Hero image gallery ──────────────────────────────────
            SliverToBoxAdapter(
              child: _ImageGalleryHeader(room: room, roomId: roomId),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title + Status badge ────────────────────────
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (room.homestay != null)
                                Text(
                                  '${room.homestay!.name} · ${room.homestay!.address}',
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppColors.muted,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.occupiedBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            room.isActive ? 'Đang ở' : 'Tạm nghỉ',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: room.isActive
                                  ? AppColors.ocean
                                  : AppColors.slate,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 10),

                    // ── Price + Rating ───────────────────────────────
                    Row(
                      children: [
                        Text(
                          room.priceDisplay,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ocean,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Info chips ───────────────────────────────────
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.bed_outlined,
                          label: '${room.bedrooms} PN',
                        ),
                        if (room.bathrooms > 0)
                          _InfoChip(
                            icon: Icons.bathtub_outlined,
                            label: '${room.bathrooms} WC',
                          ),
                        _InfoChip(
                          icon: Icons.people_outline_rounded,
                          label: '${room.maxGuests} người',
                        ),
                      ],
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),

                    // ── Amenities (từ data) ────────────────────────
                    if (room.amenities.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: room.amenities
                            .map((a) => _AmenityChip(a))
                            .toList(),
                      ),

                    const SizedBox(height: 24),

                    // ── Địa chỉ ───────────────────────────────────
                    if (room.address != null &&
                        room.address!.isNotEmpty) ...[
                      Text(
                        'Địa chỉ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              room.address!,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Mô tả ─────────────────────────────────────
                    if (room.description != null &&
                        room.description!.isNotEmpty) ...[
                      Text(
                        'Mô tả',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        room.description!,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Price grid ──────────────────────────────────
                    if (room.price != null) ...[
                      Text(
                        'Bảng giá',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PriceGrid(price: room.price!),
                      const SizedBox(height: 24),
                    ],

                    // ── Action button — chỉ Tạo booking ──────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.oceanMid,
                              AppColors.ocean,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ocean
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context
                                .push('/rooms/$roomId/hold'),
                            borderRadius: BorderRadius.circular(
                                AppRadius.md),
                            child: Center(
                              child: Text(
                                'Tạo booking',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Gallery thumbnails ──────────────────────────
                    if (room.images.length > 1) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Hình ảnh (${room.images.length})',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: room.images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () =>
                                _openGallery(context, room, i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppRadius.sm),
                              child: CachedNetworkImage(
                                imageUrl: room.images[i].imageUrl,
                                width: 110,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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

// ─── Image Gallery Header ─────────────────────────────────────────────────────
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
    final images = room.images;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        SizedBox(
          height: 260,
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
                        placeholder: (_, __) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.oceanDeep,
                                AppColors.oceanMid,
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.oceanDeep,
                                AppColors.oceanMid,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                size: 48,
                                color: AppColors.oceanLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.oceanDeep, AppColors.oceanMid],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        size: 64, color: AppColors.oceanLight),
                  ),
                ),
        ),

        // Top action buttons
        Positioned(
          top: topPadding + 8,
          left: 16,
          child: _CircleBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          top: topPadding + 8,
          right: 16,
          child: Row(
            children: [
              _CircleBtn(
                icon: Icons.favorite_outline_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _CircleBtn(
                icon: Icons.share_rounded,
                onTap: () {
                  final text =
                      '${room.code} · ${room.name}\n'
                      '${room.homestay?.address ?? ''}\n'
                      'Giá từ: ${room.priceDisplay}';
                  Share.share(text);
                },
              ),
            ],
          ),
        ),

        // Page indicators
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.oceanLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.ocean),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ocean,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}

class _PriceGrid extends StatelessWidget {
  final RoomPriceModel price;
  const _PriceGrid({required this.price});

  String _fmt(double p) {
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}tr';
    return '${(p / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _priceItem('Ngày thường', price.weekdayPrice,
                  Icons.wb_sunny_outlined, AppColors.oceanMid),
              const SizedBox(width: AppSpacing.md),
              _priceItem('Thứ 6', price.fridayPrice,
                  Icons.weekend_outlined, AppColors.purple),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _priceItem('Thứ 7', price.saturdayPrice,
                  Icons.star_outline_rounded, AppColors.amber),
              const SizedBox(width: AppSpacing.md),
              _priceItem('Lễ / Tết', price.holidayPrice,
                  Icons.celebration_outlined, AppColors.coral),
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
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_fmt(amount)}đ',
                  style: GoogleFonts.beVietnamPro(
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
              style: GoogleFonts.beVietnamPro(color: Colors.white)),
        ),
        body: PhotoViewGallery.builder(
          itemCount: images.length,
          pageController: PageController(initialPage: initialIndex),
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
