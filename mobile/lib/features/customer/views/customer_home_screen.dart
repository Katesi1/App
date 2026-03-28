import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../controllers/customer_controller.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roomsAsync = ref.watch(publicRoomsProvider(null));

    return AppScaffold(
      title: 'Halong24h',
      selectedIndex: 0,
      body: RefreshIndicator(
        color: AppColors.ocean,
        onRefresh: () async {
          ref.invalidate(publicRoomsProvider(null));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome header ────────────────────────────────
              _WelcomeHeader(name: user?.name ?? 'Khách'),

              // ── Quick actions ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Tìm phòng',
                      color: AppColors.ocean,
                      onTap: () => context.go('/search'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.book_outlined,
                      label: 'Booking',
                      color: AppColors.teal,
                      onTap: () => context.go('/my-bookings'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.phone_outlined,
                      label: 'Liên hệ',
                      color: AppColors.gold,
                      onTap: () {},
                    ),
                  ],
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),

              // ── Featured rooms ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phòng nổi bật',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/search'),
                      child: Text(
                        'Xem tất cả',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.oceanMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              roomsAsync.when(
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'Chưa có phòng nào',
                          style: GoogleFonts.beVietnamPro(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: rooms.length > 6 ? 6 : rooms.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 14),
                      itemBuilder: (_, i) => _FeaturedRoomCard(
                        room: rooms[i],
                        index: i,
                        onTap: () =>
                            context.push('/rooms/${rooms[i].id}'),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 260,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.ocean,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      e.toString().replaceAll('Exception: ', ''),
                      style: GoogleFonts.beVietnamPro(
                        color: AppColors.coral,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Info section ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Về Halong24h',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.oceanPale,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.ocean, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hạ Long, Quảng Ninh',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hệ thống lưu trú cao cấp tại Hạ Long. '
                        'Đặt phòng dễ dàng, xác nhận nhanh chóng.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Welcome Header ─────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final String name;
  const _WelcomeHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.4, -1),
          end: Alignment(0.4, 1),
          colors: [AppColors.oceanDeep, AppColors.ocean],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào,',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tìm phòng nghỉ tại Hạ Long',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0);
  }
}

// ─── Quick Action ───────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Featured Room Card ─────────────────────────────────────────────────────

class _FeaturedRoomCard extends StatelessWidget {
  final dynamic room;
  final int index;
  final VoidCallback onTap;

  const _FeaturedRoomCard({
    required this.room,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 140,
              width: double.infinity,
              child: room.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: room.coverImageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (room.homestay != null)
                    Text(
                      room.homestay!.name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        room.priceDisplay,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ocean,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${room.maxGuests}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.oceanLight, AppColors.tealLight],
          ),
        ),
        child: const Center(
          child: Icon(Icons.home_rounded,
              size: 36, color: AppColors.oceanMid),
        ),
      );
}
