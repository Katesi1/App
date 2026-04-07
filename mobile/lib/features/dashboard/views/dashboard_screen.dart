import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final now = DateTime.now();
    final dayOfWeek = AppHelpers.vietnameseDayOfWeek(now.weekday);
    final formattedDate = '$dayOfWeek, ${now.day} tháng ${now.month}';

    return AppScaffold(
      title: '',
      selectedIndex: 0,
      showAppBar: false,
      body: statsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
        data: (stats) => RefreshIndicator(
          color: AppColors.ocean,
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────
                _DashHeader(
                  userName: user?.name ?? 'Homestay',
                  formattedDate: formattedDate,
                ),

                // ── KPI Grid — overlaps header by 16px ─────────────────
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                label: 'Tổng phòng',
                                value: AppHelpers.formatIntOrDash(
                                    stats.totalRooms),
                                sub: '${AppHelpers.formatIntOrDash(stats.activeRooms)} hoạt động',
                                accentColor: AppColors.ocean,
                                icon: Icons.apartment_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiCard(
                                label: 'Phòng trống',
                                value: AppHelpers.formatIntOrDash(
                                    stats.emptyRooms),
                                sub: 'Sẵn sàng check-in',
                                accentColor: AppColors.emerald,
                                icon: Icons.check_circle_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                label: 'Đang có khách',
                                value: AppHelpers.formatIntOrDash(
                                    stats.occupiedRooms),
                                sub: 'Đang lưu trú',
                                accentColor: AppColors.teal,
                                icon: Icons.people_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiCard(
                                label: 'Check-out hôm nay',
                                value: AppHelpers.formatIntOrDash(
                                    stats.checkoutToday),
                                sub: 'Trước 12:00',
                                accentColor: AppColors.amber,
                                icon: Icons.logout_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Revenue card ────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _RevenueCard(
                    monthlyRevenue: stats.monthlyRevenue,
                    todayRevenue: stats.todayRevenue,
                    now: now,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Quick actions ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('THAO TÁC NHANH'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuickAction(
                            icon: Icons.add_rounded,
                            label: 'Booking',
                            color: AppColors.ocean,
                            onTap: () => context.go('/bookings'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.login_rounded,
                            label: 'Check-in',
                            color: AppColors.teal,
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.logout_rounded,
                            label: 'Check-out',
                            color: AppColors.gold,
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.add_home_rounded,
                            label: 'Thêm phòng',
                            color: AppColors.emerald,
                            onTap: () =>
                                context.push('/properties/new'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Booking hôm nay ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _SectionLabel('BOOKING HÔM NAY')),
                          GestureDetector(
                            onTap: () => context.go('/bookings'),
                            child: Text(
                              'Xem tất cả →',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.oceanMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BookingItem(
                        initials: '🏠',
                        name: 'Nguyễn Văn An',
                        meta: 'P.101 · Deluxe · 2 khách',
                        status: 'Đã xác nhận',
                        statusColor: AppColors.emerald,
                        statusBg: AppColors.emeraldLight,
                        price: '1.800.000đ',
                      ),
                      const SizedBox(height: 10),
                      _BookingItem(
                        initials: '🌊',
                        name: 'Trần Thị Bích',
                        meta: 'P.203 · Ocean View · 3 khách',
                        status: 'Giữ chỗ',
                        statusColor: AppColors.brownDark,
                        statusBg: AppColors.goldLight,
                        price: '2.400.000đ',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Hoạt động gần đây ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('HOẠT ĐỘNG GẦN ĐÂY'),
                      const SizedBox(height: 12),
                      _ActivityItem(
                        icon: Icons.bookmark_add_outlined,
                        iconColor: AppColors.oceanMid,
                        iconBg: AppColors.oceanLight,
                        title: 'Booking mới — Phòng 201',
                        subtitle: 'Nguyễn Thị Lan · 2 đêm · 19–21/3',
                        time: '2 phút trước',
                      ),
                      _ActivityItem(
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.emerald,
                        iconBg: AppColors.emeraldLight,
                        title: 'Check-in — Phòng 305',
                        subtitle: 'Trần Văn Nam · Đã xác nhận',
                        time: '15 phút trước',
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Dashboard Header ──────────────────────────────────────────────────────────
class _DashHeader extends StatelessWidget {
  final String userName;
  final String formattedDate;

  const _DashHeader({
    required this.userName,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkGradientStart, AppColors.darkGradientEnd]
              : [AppColors.oceanDeep, AppColors.ocean],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -50,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Xin chào, $userName 👋',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Notification
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.ocean, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Avatar
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.teal, AppColors.gold]),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── KPI Card ──────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accentColor;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              const Spacer(),
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: accentColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkOnSurface : AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Revenue Card ─────────────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final double monthlyRevenue;
  final double todayRevenue;
  final DateTime now;

  const _RevenueCard({
    required this.monthlyRevenue,
    required this.todayRevenue,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: isDark ? 0.15 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkContainer : Colors.white,
          ),
          child: Stack(
            children: [
              // Green accent left strip
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.emerald, AppColors.teal],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    // Monthly revenue
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOANH THU THÁNG ${now.month}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppHelpers.formatPriceOrDash(monthlyRevenue),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tháng ${now.month}/${now.year}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AppColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 52,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    // Today revenue
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'HÔM NAY',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppHelpers.formatPriceOrDash(todayRevenue),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.oceanMid,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thu hôm nay',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: AppColors.slate,
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
      ),
    );
  }
}

// ─── Quick Action ──────────────────────────────────────────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkContainer : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : color.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.08 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurface : AppColors.navy,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Activity Item ────────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final bool isLast;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Item ──────────────────────────────────────────────────────────────
class _BookingItem extends StatelessWidget {
  final String initials;
  final String name;
  final String meta;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String price;

  const _BookingItem({
    required this.initials,
    required this.name,
    required this.meta,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Left status stripe
            Container(
              width: 4,
              height: 64,
              color: statusColor,
            ),
            const SizedBox(width: 12),
            // Emoji avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Status + price
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    price,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ocean,
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
