import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_color_scheme.dart';
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        backgroundColor: colors.bgCanvas,
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
                                _titleText(room),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (room.homestay != null)
                                Text(
                                  '${room.homestay!.name} · ${room.homestay!.address}',
                                  style: GoogleFonts.beVietnamPro(
                                    color: colors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Builder(builder: (_) {
                          final statusColor = room.isActive
                              ? colors.success
                              : colors.textTertiary;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(
                                  alpha: isDark ? 0.18 : 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              room.isActive ? 'Hoạt động' : 'Tạm nghỉ',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          );
                        }),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 10),

                    // ── Price ────────────────────────────────────────
                    Text(
                      room.priceDisplay,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: room.price != null
                            ? colors.textBrand
                            : colors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Info chips ───────────────────────────────────
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.bed_outlined,
                          label: room.bedrooms == 0 ? 'Studio' : '${room.bedrooms} PN',
                        ),
                        if (room.bathrooms > 0)
                          _InfoChip(
                            icon: Icons.bathtub_outlined,
                            label: '${room.bathrooms} WC',
                          ),
                        _InfoChip(
                          icon: Icons.people_outline_rounded,
                          label: '${room.standardGuests} người',
                        ),
                        if (room.maxGuests > room.standardGuests)
                          _InfoChip(
                            icon: Icons.group_add_outlined,
                            label: 'Tối đa ${room.maxGuests}',
                          ),
                      ],
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 300.ms),

                    // ── Amenities ────────────────────────────────────
                    if (room.amenities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: room.amenities
                            .map((a) => _AmenityChip(a))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Địa chỉ ───────────────────────────────────
                    _DetailRow(
                      title: 'Địa chỉ',
                      icon: Icons.location_on_outlined,
                      value: room.address?.isNotEmpty == true
                          ? room.address!
                          : '-',
                    ),

                    const SizedBox(height: 16),

                    // ── Mô tả ─────────────────────────────────────
                    _DetailSection(
                      title: 'Mô tả',
                      value: room.description?.isNotEmpty == true
                          ? room.description!
                          : '-',
                    ),

                    const SizedBox(height: 24),

                    // ── Quy định + Lưu ý ──────────────────────────
                    if (room.rules != null &&
                        room.rules!.isNotEmpty) ...[
                      _DetailSection(
                        title: 'Quy định',
                        value: room.rules!.contains('\n\n--- LƯU Ý ---\n')
                            ? room.rules!.split('\n\n--- LƯU Ý ---\n')[0]
                            : room.rules!,
                      ),
                      if (room.rules!.contains('\n\n--- LƯU Ý ---\n')) ...[
                        const SizedBox(height: 16),
                        _DetailSection(
                          title: 'Lưu ý',
                          value: room.rules!.split('\n\n--- LƯU Ý ---\n')[1],
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    // ── Price grid ──────────────────────────────────
                    if (room.price != null) ...[
                      Text(
                        'Bảng giá',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PriceGrid(price: room.price!),
                      const SizedBox(height: 24),
                    ],

                    // ── Action button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [colors.brand, colors.brandLight]
                                : const [
                                    AppColors.jade900,
                                    AppColors.jade500,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(
                              AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: colors.brand
                                  .withValues(alpha: isDark ? 0.40 : 0.30),
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
                                  color: colors.textOnPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleText(RoomModel room) {
    final code = room.code.isNotEmpty ? room.code : '-';
    final name = room.name.isNotEmpty ? room.name : '-';
    return '$code · $name';
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
    final colors = context.colors;
    final room = widget.room;
    final images = room.images;
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main image area ───────────────────────────────
        Stack(
          children: [
            GestureDetector(
              onTap: images.isNotEmpty
                  ? () => _openGallery(context, images, _currentPage)
                  : null,
              child: SizedBox(
                height: 280,
                child: images.isNotEmpty
                    ? PageView.builder(
                        controller: _pageCtrl,
                        itemCount: images.length,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        itemBuilder: (_, i) => Hero(
                          tag: i == 0
                              ? 'room-cover-${room.id}'
                              : 'room-img-${room.id}-$i',
                          child: CachedNetworkImage(
                            imageUrl: images[i].imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            memCacheWidth: 800,
                            placeholder: (_, __) => _gradientBox(context),
                            errorWidget: (_, __, ___) => _gradientBox(
                              context,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: colors.brand
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      )
                    : _gradientBox(
                        context,
                        child: Icon(Icons.image_outlined,
                            size: 64,
                            color: colors.brand.withValues(alpha: 0.5)),
                      ),
              ),
            ),

            // Gradient scrim
            if (images.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),

            // Back button
            Positioned(
              top: topPadding + 8,
              left: 16,
              child: _CircleBtn(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            // Share button
            Positioned(
              top: topPadding + 8,
              right: 16,
              child: _CircleBtn(
                icon: Icons.share_rounded,
                onTap: () => Share.share(
                  _buildShareText(widget.room),
                  subject:
                      '${widget.room.code} · ${widget.room.name}',
                ),
              ),
            ),

            // Badge ảnh (luôn hiện khi có ảnh)
            if (images.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () =>
                      _openGallery(context, images, _currentPage),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          images.length == 1
                              ? 'Xem ảnh'
                              : '${_currentPage + 1} / ${images.length}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Dot indicators (chỉ khi nhiều ảnh)
            if (images.length > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length.clamp(0, 8),
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // ── Thumbnail strip (ngoài Stack, hiển thị đúng) ─
        if (images.length > 1)
          _ThumbnailStrip(
            images: images,
            selectedIndex: _currentPage,
            onTap: (i) {
              _pageCtrl.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
      ],
    );
  }

  String _buildShareText(RoomModel room) {
    final buf = StringBuffer();

    buf.writeln('🏠 ${room.code} · ${room.name}');

    if (room.homestay != null) {
      buf.writeln('📍 ${room.homestay!.name}');
      if (room.homestay!.address.isNotEmpty) {
        buf.writeln('   ${room.homestay!.address}');
      }
    } else if (room.address?.isNotEmpty == true) {
      buf.writeln('📍 ${room.address}');
    }

    buf.writeln();
    buf.writeln('━━━━━━━━━━━━━━━━━');

    // Thông tin phòng
    buf.writeln('🛏  Phòng ngủ: ${room.bedrooms}');
    if (room.bathrooms > 0) {
      buf.writeln('🚿 Phòng tắm: ${room.bathrooms}');
    }
    buf.writeln('👥 Sức chứa: tối đa ${room.maxGuests} người');
    if (room.standardGuests != room.maxGuests) {
      buf.writeln('   (tiêu chuẩn ${room.standardGuests} người)');
    }

    // Tiện ích
    if (room.amenities.isNotEmpty) {
      buf.writeln();
      buf.writeln('✅ Tiện ích:');
      for (final a in room.amenities) {
        buf.writeln('   • $a');
      }
    }

    // Mô tả
    if (room.description?.isNotEmpty == true) {
      buf.writeln();
      buf.writeln('📝 Mô tả:');
      buf.writeln(room.description);
    }

    // Phụ thu
    if (room.adultSurcharge != null && room.adultSurcharge! > 0) {
      buf.writeln();
      buf.writeln('💰 Phụ thu người lớn: ${_fmtPrice(room.adultSurcharge!)}đ/người');
    }
    if (room.childSurcharge != null && room.childSurcharge! > 0) {
      buf.writeln('💰 Phụ thu trẻ em: ${_fmtPrice(room.childSurcharge!)}đ/người');
    }

    // Chính sách huỷ
    if (room.cancellationPolicy != null) {
      const policyLabels = ['Linh hoạt', 'Vừa phải', 'Nghiêm ngặt'];
      final label = (room.cancellationPolicy! < policyLabels.length)
          ? policyLabels[room.cancellationPolicy!]
          : '${room.cancellationPolicy}';
      buf.writeln();
      buf.writeln('📋 Chính sách huỷ:');
      buf.writeln(label);
    }

    buf.writeln();
    buf.writeln('━━━━━━━━━━━━━━━━━');
    buf.write('Liên hệ để đặt phòng! 🌊');

    return buf.toString();
  }

  String _fmtPrice(double p) {
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}tr';
    return '${(p / 1000).toStringAsFixed(0)}k';
  }

  void _openGallery(
      BuildContext context, List<RoomImageModel> images, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            _GalleryScreen(images: images, initialIndex: index),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _gradientBox(BuildContext context, {Widget? child}) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [colors.bgSurfaceContainer, colors.bgSurface]
              : const [AppColors.jade900, AppColors.jade500],
        ),
      ),
      child: child != null ? Center(child: child) : null,
    );
  }
}

// ─── Thumbnail Strip ─────────────────────────────────────────────────────────
class _ThumbnailStrip extends StatefulWidget {
  final List<RoomImageModel> images;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _ThumbnailStrip({
    required this.images,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<_ThumbnailStrip> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void didUpdateWidget(_ThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tự động scroll thumbnail đến item đang chọn
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final targetOffset =
          (widget.selectedIndex * 72.0) - 100;
      _scrollCtrl.animateTo(
        targetOffset.clamp(
            0.0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.black.withValues(alpha: 0.6),
      child: ListView.builder(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 6),
        itemCount: widget.images.length,
        itemBuilder: (_, i) {
          final isSelected = i == widget.selectedIndex;
          return GestureDetector(
            onTap: () => widget.onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 44,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: CachedNetworkImage(
                  imageUrl: widget.images[i].imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 120,
                  placeholder: (_, __) => Container(
                    color: AppColors.jade900,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.jade900,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 16, color: AppColors.jade300),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
          color: Colors.black.withValues(alpha: 0.35),
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
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textBrand),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textBrand,
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
    final colors = context.colors;
    return Container(
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  const _DetailRow(
      {required this.title, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: value == '-'
                      ? colors.textTertiary
                      : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String value;
  const _DetailSection({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: value == '-'
                ? colors.textTertiary
                : colors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _priceItem('Ngày thường', price.weekdayPrice,
                  Icons.wb_sunny_outlined, colors.brand),
              const SizedBox(width: AppSpacing.md),
              _priceItem('Thứ 6', price.fridayPrice,
                  Icons.weekend_outlined, AppColors.purple),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _priceItem('Thứ 7', price.saturdayPrice,
                  Icons.star_outline_rounded, colors.warning),
              const SizedBox(width: AppSpacing.md),
              _priceItem('Lễ / Tết', price.holidayPrice,
                  Icons.celebration_outlined, colors.error),
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

// ─── Full Gallery Screen ──────────────────────────────────────────────────────
class _GalleryScreen extends StatefulWidget {
  final List<RoomImageModel> images;
  final int initialIndex;

  const _GalleryScreen(
      {required this.images, required this.initialIndex});

  @override
  State<_GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<_GalleryScreen> {
  late int _current;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          title: Text(
            '${_current + 1} / ${widget.images.length}',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${widget.images.length} ảnh',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            PhotoViewGallery.builder(
              pageController: _pageCtrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              builder: (_, i) => PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  widget.images[i].imageUrl,
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: i == 0
                      ? 'room-cover-${widget.images[i].roomId}'
                      : 'room-img-${widget.images[i].roomId}-$i',
                ),
              ),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
              loadingBuilder: (_, __) => const Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            ),
            // Thumbnail strip at bottom
            if (widget.images.length > 1)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: SafeArea(
                    child: SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm),
                        itemCount: widget.images.length,
                        itemBuilder: (_, i) {
                          final sel = i == _current;
                          return GestureDetector(
                            onTap: () => _pageCtrl.animateToPage(
                              i,
                              duration:
                                  const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppRadius.xs),
                                border: Border.all(
                                  color: sel
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppRadius.xs),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      widget.images[i].imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 120,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
