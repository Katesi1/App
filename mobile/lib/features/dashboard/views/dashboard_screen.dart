import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../verify/controllers/verify_flow_controller.dart';
import '../../verify/data/models/verify_enums.dart';
import '../../verify/views/paywall_modal.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final bookingsAsync = ref.watch(bookingListProvider(null));
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
          color: colors.brand,
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

                // ── Verify CTA cho Owner chưa verify ────────────────
                if (user != null && user.isOwner)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final s = ref.watch(verifyFlowControllerProvider);
                          // Hiện banner khi chưa approved (kể cả pending /
                          // rejected → đẩy về screen tương ứng).
                          if (s.status == VerifyStatus.approved) {
                            return const SizedBox.shrink();
                          }
                          return _VerifyCTABanner(status: s.status);
                        },
                      ),
                    ),
                  ),

                // ── Cảnh báo SALE chưa gán owner ─────────────────────
                if (user != null && user.isSale && !user.hasOwner)
                  Consumer(
                    builder: (context, ref, _) {
                      final dismissed =
                          ref.watch(unassignedBannerDismissedProvider);
                      if (dismissed) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Transform.translate(
                          offset: const Offset(0, -16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colors.warningBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: colors.warning, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      'Bạn chưa được gán cho chủ nhà nào. Hãy liên hệ chủ nhà để được thêm vào đội.',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: colors.warning,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => ref
                                      .read(unassignedBannerDismissedProvider
                                          .notifier)
                                      .state = true,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: colors.warning
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
                                    stats.globalTotalRooms),
                                sub: '${AppHelpers.formatIntOrDash(stats.totalRooms)} của tôi',
                                accentColor: colors.brand,
                                icon: Icons.apartment_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiCard(
                                label: 'Phòng trống',
                                value: AppHelpers.formatIntOrDash(
                                    stats.globalEmptyRooms),
                                sub: '${AppHelpers.formatIntOrDash(stats.emptyRooms)} của tôi',
                                accentColor: colors.success,
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
                                accentColor: colors.brandLight,
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
                                accentColor: colors.warning,
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
                            color: colors.brand,
                            onTap: () => context.push('/bookings'),
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.login_rounded,
                            label: 'Check-in',
                            color: colors.brandLight,
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: Icons.logout_rounded,
                            label: 'Check-out',
                            color: colors.brandSecondary,
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          if (user?.canManageProperty ?? false)
                            _QuickAction(
                              icon: Icons.add_home_rounded,
                              label: 'Thêm phòng',
                              color: colors.success,
                              onTap: () =>
                                  context.push('/properties/new'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Shortcut quản lý phòng + lịch CHỈ cho SALE ──────────
                // OWNER/ADMIN đã có bottom nav + admin tab nên không cần.
                // SALE chưa được gán owner → lock; có owner → vào dữ liệu
                // của owner (backend auto-scope theo ownerId của SALE).
                if (user != null && user.isSale) ...[
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('QUẢN LÝ'),
                        const SizedBox(height: 12),
                        _ManageShortcut(
                          icon: Icons.apartment_rounded,
                          iconColor: colors.brand,
                          title: 'Quản lý phòng',
                          subtitle:
                              'Xem & cập nhật phòng của chủ nhà bạn phụ trách',
                          locked: !user.hasOwner,
                          onTap: () => context.go('/rooms'),
                        ),
                        const SizedBox(height: 10),
                        _ManageShortcut(
                          icon: Icons.calendar_month_rounded,
                          iconColor: colors.brandLight,
                          title: 'Lịch booking',
                          subtitle:
                              'Xem lịch booking các phòng của chủ nhà',
                          locked: !user.hasOwner,
                          onTap: () => context.go('/calendar'),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Booking gần đây ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _SectionLabel('BOOKING GẦN ĐÂY')),
                          GestureDetector(
                            onTap: () => context.push('/bookings'),
                            child: Text(
                              'Xem tất cả →',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textBrand,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      bookingsAsync.when(
                        loading: () => const SizedBox(
                          height: 60,
                          child: Center(child: LoadingWidget()),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (bookings) {
                          if (bookings.isEmpty) {
                            return const EmptyStateWidget(
                              icon: Icons.book_outlined,
                              message: 'Chưa có booking nào',
                            );
                          }
                          final recent = bookings.take(5).toList();
                          return Column(
                            children: recent.map((b) {
                              final statusColor =
                                  AppHelpers.bookingStatusColor(
                                      b.status.value);
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: _BookingItem(
                                  initials: (b.customerName ?? 'K')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  name: b.customerName ?? 'Không tên',
                                  meta:
                                      '${b.propertyName} · ${b.nights} đêm',
                                  status: b.status.label,
                                  statusColor: statusColor,
                                  statusBg:
                                      statusColor.withValues(alpha: 0.12),
                                  price: (b.depositAmount != null &&
                                          b.depositAmount! > 0)
                                      ? '${AppHelpers.formatPrice(b.depositAmount!)}đ'
                                      : '--',
                                  onTap: () =>
                                      context.push('/bookings'),
                                ),
                              );
                            }).toList(),
                          );
                        },
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
    final colors = context.colors;
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 32,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerGradient,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
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
                color: colors.brandLight.withValues(alpha: 0.10),
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
                color: AppColors.gold500.withValues(alpha: 0.08),
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
                          color: AppColors.gold500,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.jade500, width: 1.5),
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
                        colors: [AppColors.jade300, AppColors.gold500]),
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
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
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: colors.textTertiary,
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.success.withValues(alpha: isDark ? 0.15 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors.success, colors.brandLight],
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
                              color: colors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppHelpers.formatPriceOrDash(monthlyRevenue),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: colors.success,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tháng ${now.month}/${now.year}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 52,
                      color: colors.borderDefault,
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
                            color: colors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppHelpers.formatPriceOrDash(todayRevenue),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.brandLight,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thu hôm nay',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: colors.textTertiary,
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? colors.borderDefault
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
                  color: colors.textPrimary,
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

// ─── Manage Shortcut (row card lớn, dùng cho /rooms + /calendar) ──────────────
class _ManageShortcut extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool locked;

  const _ManageShortcut({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: locked
          ? () => AppSnackBar.info(
                context,
                'Bạn cần được chủ nhà thêm vào đội trước khi quản lý phòng & lịch.',
              )
          : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: locked
                ? Border.all(
                    color: colors.borderDefault,
                    style: BorderStyle.solid,
                  )
                : null,
            boxShadow: locked
                ? null
                : [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.30 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (locked ? colors.textTertiary : iconColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: locked ? colors.textTertiary : iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locked
                          ? 'Chờ chủ nhà thêm bạn vào đội để mở khoá'
                          : subtitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                locked
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                color: colors.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
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
  final VoidCallback? onTap;

  const _BookingItem({
    required this.initials,
    required this.name,
    required this.meta,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
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
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textSecondary,
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
                      color: colors.textBrand,
                    ),
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

/// Banner nổi bật trên dashboard cho Owner chưa verify (hoặc đang chờ /
/// bị reject). Tap → showPaywallModal hoặc đẩy thẳng về screen tương ứng
/// với status hiện tại.
class _VerifyCTABanner extends StatelessWidget {
  final VerifyStatus status;
  const _VerifyCTABanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Mọi màu derive từ `context.colors` (theme-aware) thay vì hardcode
    // *Dark constants — banner phải đẹp ở cả light và dark.
    final (
      Color bg,
      Color borderColor,
      Color iconBg,
      IconData icon,
      Color iconColor,
      String title,
      String subtitle,
      String cta,
      String route,
      bool useModal,
    ) = switch (status) {
      VerifyStatus.awaitingApproval => (
          colors.bgSurfaceContainer,
          colors.borderBrand.withValues(alpha: 0.4),
          colors.brand.withValues(alpha: 0.15),
          Icons.access_time,
          colors.brand,
          'Hồ sơ đang chờ admin duyệt',
          'Trong vòng 24h sẽ có kết quả.',
          'Xem trạng thái',
          '/verify/pending',
          false,
        ),
      VerifyStatus.rejected => (
          colors.errorBg,
          colors.error.withValues(alpha: 0.4),
          colors.error.withValues(alpha: 0.15),
          Icons.priority_high,
          colors.error,
          'Hồ sơ chưa được duyệt',
          'Cần bổ sung thông tin để được kích hoạt.',
          'Bổ sung ngay',
          '/verify/rejected',
          false,
        ),
      _ => (
          colors.bgWarm,
          colors.borderGold,
          colors.borderGold.withValues(alpha: 0.3),
          Icons.workspace_premium,
          colors.textBrandAccent,
          'Verify để bắt đầu nhận booking',
          '4 bước · Trial 7 ngày miễn phí khi xong.',
          'Bắt đầu',
          '/verify/cccd-front',
          true,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CTAButton(
            label: cta,
            onTap: () async {
              if (useModal) {
                final ok = await showPaywallModal(context);
                if (ok == true && context.mounted) {
                  context.push(route);
                }
              } else {
                context.push(route);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CTAButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CTAButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.brand,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textOnPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward,
                size: 12, color: colors.textOnPrimary),
          ],
        ),
      ),
    );
  }
}
