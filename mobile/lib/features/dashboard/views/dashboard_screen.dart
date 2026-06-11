import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../verify/data/models/verify_enums.dart';
import '../../verify/views/paywall_modal.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pagination_bar.dart';

// gradient.brandHero stop "jade-mid" per spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

/// Maps backend `kycStatus` (`none|pending|rejected|approved`) to
/// [VerifyStatus] so [_VerifyCTABanner] knows which variant to render.
VerifyStatus _verifyStatusFromUserKyc(String kycStatus) {
  switch (kycStatus) {
    case 'pending':
      return VerifyStatus.awaitingApproval;
    case 'rejected':
      return VerifyStatus.rejected;
    case 'approved':
      return VerifyStatus.approved;
    case 'none':
    default:
      return VerifyStatus.draft;
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
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
          color: colors.brand,
          onRefresh: () async {
            // Refresh stats + user profile together to catch backend-side
            // KYC/subscription status changes (e.g. admin just approved KYC).
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(bookingListProvider(null));
            await ref.read(authProvider.notifier).refreshProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashHeader(
                  userName: user?.name ?? 'Homestay',
                  formattedDate: formattedDate,
                ),

                // Verify CTA for unverified Owner — KYC is the only gate to
                // create rooms. Source of truth: user.kycStatus from
                // /auth/profile (backend), NOT verifyFlowController (local).
                // The banner itself drops all payment/trial wording on iOS
                // (see _VerifyCTABanner).
                if (user != null && user.isOwner && !user.isKycApproved)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: _VerifyCTABanner(
                        status: _verifyStatusFromUserKyc(user.kycStatus),
                      ),
                    ),
                  ),

                // Subscription banner for OWNER with approved KYC.
                // Trial / past_due / cancelled — hidden when active.
                // Hidden entirely on iOS (Guideline 3.1.1: no paid-upgrade UI).
                if (AppConfig.showPaidUpgradeUI &&
                    user != null &&
                    user.isOwner &&
                    user.isKycApproved &&
                    !user.isSubscriptionActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Transform.translate(
                      offset: const Offset(0, -16),
                      child: _SubscriptionBanner(user: user),
                    ),
                  ),

                // SALE not yet assigned to owner warning.
                if (user != null &&
                    user.isSale &&
                    !user.isSaleMembershipActive)
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
                                      switch (user.saleMembershipState) {
                                        'invited' =>
                                          'Tài khoản của bạn đang chờ chủ nhà kích hoạt phân quyền.',
                                        'suspended' =>
                                          'Phân quyền của bạn đang tạm khóa. Liên hệ chủ nhà để mở lại.',
                                        _ =>
                                          'Bạn chưa được gán cho chủ nhà nào. Hãy liên hệ chủ nhà để được thêm vào đội.',
                                      },
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
                                      color:
                                          colors.warning.withValues(alpha: 0.7),
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
                                sub:
                                    '${AppHelpers.formatIntOrDash(stats.totalRooms)} của tôi',
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
                                sub:
                                    '${AppHelpers.formatIntOrDash(stats.emptyRooms)} của tôi',
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                      SizedBox(
                        height: 96,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          // Compensates parent Column's horizontal: 16 so first/last
                          // items don't touch screen edges.
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
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
                              onTap: () => context.push('/front-desk'),
                            ),
                            const SizedBox(width: 10),
                            _QuickAction(
                              icon: Icons.logout_rounded,
                              label: 'Check-out',
                              color: colors.brandSecondary,
                              onTap: () =>
                                  context.push('/front-desk?tab=departures'),
                            ),
                            if (user?.canManageProperty ?? false) ...[
                              const SizedBox(width: 10),
                              _QuickAction(
                                icon: Icons.add_home_rounded,
                                label: 'Thêm phòng',
                                color: colors.success,
                                onTap: () => context.push('/properties/new'),
                              ),
                            ],
                            if (user?.isOwner ?? false) ...[
                              const SizedBox(width: 10),
                              _QuickAction(
                                icon: Icons.group_add_rounded,
                                label: 'Nhân viên',
                                color: colors.brandSecondary,
                                onTap: () => context.push('/staff/manage'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Room + calendar management shortcut — SALE only.
                // OWNER/ADMIN already have bottom nav + admin tab.
                // SALE without assigned owner → locked; with owner → enters
                // owner's data (backend auto-scopes by SALE's ownerId).
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
                          locked: !user.isSaleMembershipActive,
                          onTap: () => context.go('/rooms'),
                        ),
                        const SizedBox(height: 10),
                        _ManageShortcut(
                          icon: Icons.calendar_month_rounded,
                          iconColor: colors.brandLight,
                          title: 'Lịch booking',
                          subtitle: 'Xem lịch booking các phòng của chủ nhà',
                          locked: !user.isSaleMembershipActive,
                          onTap: () => context.go('/calendar'),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Recent bookings section.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _SectionLabel('BOOKING GẦN ĐÂY')),
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
                      const _DashboardRecentBookingsSection(),
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

// Recent bookings section (paginated).
class _DashboardRecentBookingsSection extends ConsumerStatefulWidget {
  const _DashboardRecentBookingsSection();

  @override
  ConsumerState<_DashboardRecentBookingsSection> createState() =>
      _DashboardRecentBookingsSectionState();
}

class _DashboardRecentBookingsSectionState
    extends ConsumerState<_DashboardRecentBookingsSection> {
  static const int _pageSize = 5;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingListProvider(null));

    return async.when(
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

        final totalPages = (bookings.length + _pageSize - 1) ~/ _pageSize;
        final safePage = totalPages == 0 ? 0 : _page.clamp(0, totalPages - 1);
        if (safePage != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _page = safePage);
          });
        }

        final start = safePage * _pageSize;
        final end = start + _pageSize > bookings.length
            ? bookings.length
            : start + _pageSize;
        final pageItems = bookings.sublist(start, end);

        return Column(
          children: [
            ...pageItems.map((b) {
              final statusColor = AppHelpers.bookingStatusColor(b.status.value);
              final rawName = (b.customerName ?? '').trim();
              final initials = rawName.isNotEmpty
                  ? rawName.substring(0, 1).toUpperCase()
                  : 'K';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BookingItem(
                  initials: initials,
                  name: b.customerName ?? 'Không tên',
                  meta: '${b.propertyName} · ${b.nights} đêm',
                  status: b.status.label,
                  statusColor: statusColor,
                  statusBg: statusColor.withValues(alpha: 0.12),
                  price: (b.depositAmount != null && b.depositAmount! > 0)
                      ? '${AppHelpers.formatPrice(b.depositAmount!)}đ'
                      : '--',
                  onTap: () => context.push('/bookings'),
                ),
              );
            }),
            if (totalPages > 1)
              AppPaginationBar(
                currentPage: safePage,
                totalPages: totalPages,
                onPrevious: safePage > 0
                    ? () => setState(() => _page = safePage - 1)
                    : null,
                onNext: safePage < totalPages - 1
                    ? () => setState(() => _page = safePage + 1)
                    : null,
              ),
          ],
        );
      },
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
                          border:
                              Border.all(color: AppColors.jade500, width: 1.5),
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
                        color: Colors.white.withValues(alpha: 0.3), width: 1.5),
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

    return SizedBox(
      width: 86,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isDark ? colors.borderDefault : color.withValues(alpha: 0.15),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Manage Shortcut (large row card, used for /rooms + /calendar).
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
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
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
                  child: Text(initials, style: const TextStyle(fontSize: 20)),
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

/// Subscription banner for OWNER with approved KYC.
/// 3 variants: trial countdown / past_due (payment needed) / cancelled.
/// Active state is hidden (caller already guards).
class _SubscriptionBanner extends ConsumerWidget {
  final UserModel user;
  const _SubscriptionBanner({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    // Trial variant allows dismiss (positive). Past-due / cancelled do not.
    final isTrial = user.isInTrial;
    final dismissed =
        isTrial && ref.watch(trialBannerDismissedProvider);
    if (dismissed) return const SizedBox.shrink();

    final (
      Gradient gradient,
      Color borderColor,
      IconData icon,
      Color iconColor,
      Color titleColor,
      Color subtitleColor,
      String title,
      String subtitle,
    ) = _resolveVariant(colors);

    return InkWell(
      onTap: () => _showDetailSheet(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isTrial
              ? [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: iconColor),
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
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isTrial)
              // X dismiss button — only for trial (positive variant).
              GestureDetector(
                onTap: () => ref
                    .read(trialBannerDismissedProvider.notifier)
                    .state = true,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: subtitleColor,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: subtitleColor,
              ),
          ],
        ),
      ),
    );
  }

  /// Subscription detail bottom sheet. Tap the support CTA → /profile/help.
  void _showDetailSheet(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (title, body, ctaLabel) = _sheetContent();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(sheetCtx).maybePop();
                  // Users without a live paid plan (trial / not subscribed /
                  // cancelled) go straight to the plan picker so they can
                  // CHOOSE a tier. Only an active/past-due subscriber lands on
                  // the manage screen (đổi gói / huỷ / khôi phục).
                  final hasPaidPlan =
                      user.isSubscriptionActive || user.isSubscriptionPastDue;
                  context.push(hasPaidPlan
                      ? '/verify/subscription-detail'
                      : '/verify/select-plan');
                },
                icon: const Icon(
                  Icons.workspace_premium_outlined,
                  size: 18,
                ),
                label: Text(ctaLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: AppColors.darkBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet content per variant: title / body / CTA label.
  (String, String, String) _sheetContent() {
    final plan = user.subscriptionPlanId ?? '—';
    final cycle = switch (user.subscriptionCycle) {
      'monthly' => 'Hàng tháng',
      'yearly' => 'Hàng năm',
      _ => '',
    };
    final planText = cycle.isEmpty ? plan : '$plan · $cycle';

    if (user.isInTrial) {
      final days = user.trialDaysLeft ?? 0;
      return (
        'Đang dùng thử miễn phí',
        'Gói: $planText\n'
            'Còn $days ngày trial.\n'
            'Khi trial kết thúc, hệ thống tự động trừ tiền theo gói đã chọn. '
            'Bạn có thể đổi gói hoặc huỷ bất cứ lúc nào.',
        'Quản lý gói đăng ký',
      );
    }
    if (user.isSubscriptionPastDue) {
      return (
        'Thanh toán quá hạn',
        'Gói: $planText\n\n'
            'Lần thanh toán gần nhất bị từ chối. Vui lòng cập nhật phương thức '
            'thanh toán mới hoặc liên hệ hỗ trợ để tránh gián đoạn dịch vụ.',
        'Cập nhật thanh toán',
      );
    }
    if (user.isSubscriptionCancelled) {
      return (
        'Subscription đã huỷ',
        'Gói: $planText\n\n'
            'Tài khoản đã bị tạm ngưng nhận booking. Đăng ký gói mới để kích '
            'hoạt lại.',
        'Đăng ký gói mới',
      );
    }
    // KYC approved but no plan picked yet — decoupled purchase flow.
    return (
      'Chưa chọn gói thanh toán',
      'Tài khoản đã xác minh xong. Chọn gói phù hợp số phòng để bắt đầu '
          'nhận booking.',
      'Chọn gói ngay',
    );
  }

  /// Returns tuple: (gradient, borderColor, icon, iconColor, titleColor,
  /// subtitleColor, title, subtitle).
  (Gradient, Color, IconData, Color, Color, Color, String, String)
      _resolveVariant(AppColorScheme colors) {
    // Trial — emerald/teal gradient (positive, fresh, premium feel)
    if (user.isInTrial) {
      final days = user.trialDaysLeft ?? 0;
      final daysText = days > 0 ? 'còn $days ngày' : 'kết thúc hôm nay';
      return (
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0F7F4), // mint light
            Color(0xFFCDE9FF), // sky pastel
          ],
        ),
        const Color(0xFF7FCBC1), // emerald soft border
        Icons.workspace_premium_outlined,
        const Color(0xFF0A6B5E), // deep teal icon
        const Color(0xFF0A4F45), // dark teal title
        const Color(0xFF1F6A60), // muted teal subtitle
        'Đang dùng thử miễn phí · $daysText',
        days > 0
            ? 'Sau khi trial kết thúc, hệ thống tự động trừ tiền theo gói đã chọn.'
            : 'Hệ thống sẽ tự động charge theo gói đã chọn vào ngày mai.',
      );
    }
    // Past due — payment failed, needs update (red — action required).
    if (user.isSubscriptionPastDue) {
      return (
        LinearGradient(
          colors: [AppColors.errorBgDark, AppColors.errorBgDark],
        ),
        AppColors.errorBorder,
        Icons.priority_high_rounded,
        colors.error,
        colors.textPrimary,
        colors.textSecondary,
        'Thanh toán quá hạn',
        'Tài khoản sẽ bị khoá nếu không cập nhật phương thức thanh toán.',
      );
    }
    // Cancelled — subscription was cancelled.
    if (user.isSubscriptionCancelled) {
      return (
        LinearGradient(
          colors: [AppColors.darkContainer, AppColors.darkContainer],
        ),
        AppColors.darkBorder,
        Icons.cancel_outlined,
        colors.textSecondary,
        colors.textPrimary,
        colors.textSecondary,
        'Subscription đã huỷ',
        'Liên hệ hỗ trợ nếu muốn tiếp tục sử dụng.',
      );
    }
    // KYC approved but no subscription yet — main CTA to /verify/select-plan.
    return (
      LinearGradient(
        colors: [AppColors.infoBgDark, AppColors.infoBgDark],
      ),
      AppColors.darkBorder,
      Icons.workspace_premium_outlined,
      colors.brandLight,
      colors.textPrimary,
      colors.textSecondary,
      'Chọn gói để bắt đầu',
      'Tài khoản đã xác minh. Chọn gói thanh toán để nhận booking.',
    );
  }
}

/// Prominent dashboard banner for unverified Owner (or pending/rejected).
/// Tap → showPaywallModal or routes to the screen matching current status.
class _VerifyCTABanner extends StatelessWidget {
  final VerifyStatus status;
  const _VerifyCTABanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // All colors derive from `context.colors` (theme-aware) instead of
    // hardcoded *Dark constants — banner must look good in light and dark.
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
      // Default (kycStatus none): prompt identity verification. On iOS no
      // trial/payment wording and no paywall modal — straight to CCCD capture.
      _ => (
          colors.bgWarm,
          colors.borderGold,
          colors.borderGold.withValues(alpha: 0.3),
          Icons.workspace_premium,
          colors.textBrandAccent,
          AppConfig.hidePaidUpgradeUI
              ? 'Xác thực danh tính để đăng phòng'
              : 'Verify để bắt đầu nhận booking',
          AppConfig.hidePaidUpgradeUI
              ? 'Xác minh CCCD + selfie · admin duyệt trong 24h.'
              : '4 bước · Trial 7 ngày miễn phí khi xong.',
          AppConfig.hidePaidUpgradeUI ? 'Xác thực' : 'Bắt đầu',
          '/verify/cccd-front',
          AppConfig.showPaidUpgradeUI, // useModal: false on iOS → direct capture
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
                final resumeRoute = await showPaywallModal(context);
                if (resumeRoute != null && context.mounted) {
                  context.push(resumeRoute);
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
            Icon(Icons.arrow_forward, size: 12, color: colors.textOnPrimary),
          ],
        ),
      ),
    );
  }
}
