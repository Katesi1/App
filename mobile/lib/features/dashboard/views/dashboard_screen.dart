import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final now = DateTime.now();
    final dayOfWeek = AppHelpers.vietnameseDayOfWeek(now.weekday);
    final formattedDate = '$dayOfWeek, ${now.day} tháng ${now.month}';

    return AppScaffold(
      title: '',
      selectedIndex: 0,
      showAppBar: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header gradient ─────────────────────────────────────
            _DashHeader(
              userName: user?.name ?? 'Homestay',
              formattedDate: formattedDate,
            ),

            // ── KPI Grid (2 cols × 3 rows) ──────────────────────────
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Row 1: Tổng phòng | Phòng trống
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: 'Tổng phòng',
                            value: '24',
                            delta: '↑ 2 so với tháng trước',
                            deltaUp: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiCard(
                            label: 'Phòng trống',
                            value: '8',
                            delta: 'Sẵn sàng check-in',
                            deltaUp: true,
                            valueColor: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 2: Đang có khách | Check-out hôm nay
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            label: 'Đang có khách',
                            value: '12',
                            delta: '↑ 3 so với hôm qua',
                            deltaUp: true,
                            valueColor: AppColors.oceanMid,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiCard(
                            label: 'Check-out hôm nay',
                            value: '4',
                            delta: 'Trước 12:00',
                            deltaUp: true,
                            valueColor: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 3: Doanh thu tháng
                    _RevenueCard(),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              ),
            ),

            const SizedBox(height: 0),

            // ── Quick actions ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THAO TÁC NHANH',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'Thêm\nbooking',
                        bgColor: AppColors.oceanLight,
                        iconColor: AppColors.ocean,
                        onTap: () => context.go('/bookings'),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Check-in',
                        bgColor: AppColors.tealLight,
                        iconColor: AppColors.oceanMid,
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.logout_rounded,
                        label: 'Check-out',
                        bgColor: AppColors.goldLight,
                        iconColor: AppColors.gold,
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.home_outlined,
                        label: 'Thêm\nphòng',
                        bgColor: AppColors.emeraldLight,
                        iconColor: AppColors.emerald,
                        onTap: () => context.push('/rooms/new'),
                      ),
                    ],
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            ),

            const SizedBox(height: 24),

            // ── Hoạt động gần đây ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOẠT ĐỘNG GẦN ĐÂY',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActivityItem(
                    icon: Icons.bookmark_add_outlined,
                    iconColor: AppColors.oceanMid,
                    iconBg: AppColors.oceanLight,
                    title: 'Booking mới — Phòng 201',
                    subtitle: 'Nguyễn Thị Lan · 2 đêm · 19–21/3',
                    time: '2p',
                  ),
                  const SizedBox(height: 8),
                  _ActivityItem(
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.emerald,
                    iconBg: AppColors.emeraldLight,
                    title: 'Check-in — Phòng 305',
                    subtitle: 'Trần Văn Nam · Đã xác nhận',
                    time: '15p',
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            ),

            const SizedBox(height: 24),

            // ── Today's bookings ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKING HÔM NAY',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      letterSpacing: 0.8,
                    ),
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
                  const SizedBox(height: 8),
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
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            ),

            const SizedBox(height: 100),
          ],
        ),
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
        top: MediaQuery.of(context).padding.top,
        bottom: 44,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.4, -1),
          end: const Alignment(0.4, 1),
          colors: isDark
              ? [AppColors.darkGradientStart, AppColors.darkGradientEnd]
              : [AppColors.oceanDeep, AppColors.ocean],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Date + Notification + Avatar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Xin chào, $userName 👋',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Stack(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.ocean,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Avatar
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.teal, AppColors.gold],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
  final String delta;
  final bool deltaUp;
  final Color? valueColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaUp,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: deltaUp ? AppColors.emerald : AppColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Revenue Card ─────────────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Doanh thu tháng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOANH THU THÁNG ${now.month}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '184.5',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
                Text(
                  'tr',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '↑ 12.4% so với tháng ${now.month - 1}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
          ),
          // Hôm nay
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'HÔM NAY',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '6.2',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.oceanMid,
                      ),
                    ),
                    TextSpan(
                      text: 'tr',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.oceanMid,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '/ 7.8tr mục tiêu',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
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

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
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
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppColors.muted,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Room thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.oceanLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(initials, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
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
          // Status + Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}
