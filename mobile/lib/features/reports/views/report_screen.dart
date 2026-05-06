import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../data/models/booking_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/report_controller.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  Widget _header(BuildContext context, WidgetRef ref, DateTime now) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? user?.phone ?? '';

    final headerGradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerGradient,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -50,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
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
              width: 100,
              height: 100,
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
                      'Báo cáo',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thống kê tháng ${now.month}/${now.year}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.jade500, AppColors.gold500]),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = DateTime.now();
    final reportAsync = ref.watch(reportDataProvider(null));

    return AppScaffold(
      title: '',
      selectedIndex: 3,
      showAppBar: false,
      body: Column(
        children: [
          _header(context, ref, now),
          Expanded(
            child: reportAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(reportDataProvider(null)),
              ),
              data: (report) {
                final totalRooms = report.totalRooms;
                final activeRooms = report.activeRooms;
                final holdCount = report.holdCount;
                final confirmedCount = report.confirmedCount;
                final cancelledCount = report.cancelledCount;
                final completedCount = report.completedCount;
                final totalBookings = report.totalBookings;
                final totalDeposit = report.totalDeposit;
                final thisMonthCount = report.thisMonthBookings;
                final occupancyRate = report.occupancyRate;

                return RefreshIndicator(
                  color: colors.brand,
                  onRefresh: () async {
                    ref.invalidate(reportDataProvider(null));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── KPI Cards (2x2) ────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.apartment_rounded,
                              iconBg: colors.bgSurfaceContainer,
                              iconColor: colors.brand,
                              label: 'Tổng phòng',
                              value: '$totalRooms',
                              sub: '$activeRooms đang hoạt động',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.percent_rounded,
                              iconBg: colors.successBg,
                              iconColor: colors.success,
                              label: 'Tỷ lệ lấp đầy',
                              value: '${occupancyRate.toStringAsFixed(0)}%',
                              sub: 'Phòng có booking',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.book_rounded,
                              iconBg: colors.bgSurfaceContainer,
                              iconColor: colors.brandLight,
                              label: 'Tổng booking',
                              value: '$totalBookings',
                              sub: '$thisMonthCount tháng này',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.payments_rounded,
                              iconBg: colors.warningBg,
                              iconColor: AppColors.gold500,
                              label: 'Tiền cọc thu',
                              value: totalDeposit > 0
                                  ? AppHelpers.formatPrice(totalDeposit)
                                  : '--',
                              sub: 'Đã xác nhận + hoàn thành',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Booking Status Breakdown ───────
                      const _SectionTitle(title: 'TRẠNG THÁI BOOKING'),
                      const SizedBox(height: 12),

                      _CardContainer(
                        child: Column(
                          children: [
                            _StatusRow(
                              label: 'Đang giữ',
                              count: holdCount,
                              total: totalBookings,
                              color: colors.warning,
                            ),
                            const SizedBox(height: 12),
                            _StatusRow(
                              label: 'Đã xác nhận',
                              count: confirmedCount,
                              total: totalBookings,
                              color: colors.success,
                            ),
                            const SizedBox(height: 12),
                            _StatusRow(
                              label: 'Hoàn thành',
                              count: completedCount,
                              total: totalBookings,
                              color: colors.brandLight,
                            ),
                            const SizedBox(height: 12),
                            _StatusRow(
                              label: 'Đã huỷ',
                              count: cancelledCount,
                              total: totalBookings,
                              color: colors.error,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Phòng theo homestay ────────────
                      const _SectionTitle(title: 'THÔNG TIN PHÒNG'),
                      const SizedBox(height: 12),

                      _CardContainer(
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Tổng số phòng',
                              value: '$totalRooms',
                            ),
                            Divider(height: 20, color: colors.borderDefault),
                            _InfoRow(
                              label: 'Phòng hoạt động',
                              value: '$activeRooms',
                              valueColor: colors.success,
                            ),
                            Divider(height: 20, color: colors.borderDefault),
                            _InfoRow(
                              label: 'Phòng tạm ngưng',
                              value: '${totalRooms - activeRooms}',
                              valueColor: colors.textTertiary,
                            ),
                            Divider(height: 20, color: colors.borderDefault),
                            _InfoRow(
                              label: 'Có ảnh bìa',
                              value: '${report.roomsWithCover}',
                            ),
                            Divider(height: 20, color: colors.borderDefault),
                            _InfoRow(
                              label: 'Đã cập nhật giá',
                              value: '${report.roomsWithPrice}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Booking gần đây ────────────────
                      const _SectionTitle(title: 'BOOKING GẦN ĐÂY'),
                      const SizedBox(height: 12),

                      if (report.recentBookings.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.book_outlined,
                          message: 'Chưa có booking nào',
                        )
                      else
                        ...report.recentBookings.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => context.push('/bookings'),
                              child: _RecentBookingCard(booking: b),
                            ),
                          ),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Container (theme-aware shadow) ─────────────────────────────────────
class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
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

// ─── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      title,
      style: GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Status Row with progress bar ─────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = total > 0 ? count / total : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${(ratio * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: colors.bgSurfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Recent Booking Card ──────────────────────────────────────────────────────
class _RecentBookingCard extends StatelessWidget {
  final BookingModel booking;
  const _RecentBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusLabel = booking.status.label;
    final statusColor = AppHelpers.bookingStatusColor(booking.status.value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
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
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.book_outlined,
              color: colors.brand,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Không tên',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.propertyName} · ${booking.nights} đêm',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
