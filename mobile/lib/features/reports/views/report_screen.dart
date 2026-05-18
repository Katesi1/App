import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/booking_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import 'widgets/extra_charts.dart';
import 'widgets/property_ratings_section.dart';
import 'widgets/report_format.dart';
import 'widgets/revenue_trend_chart.dart';
import 'widgets/status_donut_chart.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final params = ref.watch(selectedReportParamsProvider);
    final reportAsync = ref.watch(reportDataProvider(params));

    return AppScaffold(
      title: '',
      selectedIndex: 3,
      showAppBar: false,
      body: Column(
        children: [
          _Header(period: params.period),
          Expanded(
            child: reportAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(reportDataProvider(params)),
              ),
              data: (report) => RefreshIndicator(
                color: colors.brand,
                onRefresh: () async =>
                    ref.invalidate(reportDataProvider(params)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: [
                    _PeriodSelector(
                      current: params.period,
                      onChanged: (p) {
                        ref.read(selectedReportParamsProvider.notifier).state =
                            params.copyWith(period: p);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _KpiGrid(report: report),
                    const SizedBox(height: AppSpacing.md),

                    RevenueTrendChart(points: report.revenueByDay),
                    const SizedBox(height: AppSpacing.md),

                    DayOfWeekChart(data: report.dayOfWeekOccupancy),
                    const SizedBox(height: AppSpacing.md),

                    LengthOfStayChart(distribution: report.lengthOfStay),
                    const SizedBox(height: AppSpacing.md),

                    _SectionTitle(title: 'TRẠNG THÁI BOOKING'),
                    const SizedBox(height: 8),
                    StatusDonutChart(
                      holdCount: report.holdCount,
                      confirmedCount: report.confirmedCount,
                      completedCount: report.completedCount,
                      cancelledCount: report.cancelledCount,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (report.topRooms.isNotEmpty) ...[
                      _SectionTitle(title: 'TOP PHÒNG DOANH THU'),
                      const SizedBox(height: 8),
                      _TopRoomsList(rooms: report.topRooms),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    _SectionTitle(title: 'ĐÁNH GIÁ KHÁCH'),
                    const SizedBox(height: 8),
                    PropertyRatingsSection(
                      ratings: report.propertyRatings,
                      reviews: report.recentReviews,
                      overallAvgRating: report.overallAvgRating,
                      overallTotalReviews: report.overallTotalReviews,
                      overallDistribution: report.overallDistribution,
                    ),
                    if (!report.overallBreakdown.isEmpty) ...[
                      const SizedBox(height: 12),
                      CriteriaBreakdownCard(breakdown: report.overallBreakdown),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    _SectionTitle(title: 'BOOKING GẦN ĐÂY'),
                    const SizedBox(height: 8),
                    if (report.recentBookings.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.book_outlined,
                        message: 'Chưa có booking nào',
                      )
                    else
                      _PaginatedRecentBookings(
                        key: ValueKey(report.recentBookings.length),
                        bookings: report.recentBookings,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final ReportPeriod period;
  const _Header({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      'Thống kê ${period.label.toLowerCase()}',
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

// ─── Period selector ───────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final ReportPeriod current;
  final ValueChanged<ReportPeriod> onChanged;

  const _PeriodSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReportPeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = ReportPeriod.values[i];
          final selected = p == current;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? colors.brand : colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: selected ? colors.brand : colors.borderDefault,
                ),
              ),
              child: Text(
                p.label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.textOnPrimary : colors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── KPI grid ──────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final ReportData report;
  const _KpiGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.payments_rounded,
                iconColor: colors.success,
                label: 'Doanh thu',
                value: ReportFormat.vndShort(report.revenue),
                fullValue: ReportFormat.vndFull(report.revenue),
                delta: ReportFormat.percentDelta(
                  report.revenue,
                  report.previousPeriod.revenue,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                icon: Icons.percent_rounded,
                iconColor: colors.brand,
                label: 'Lấp đầy',
                value: '${report.occupancyRate.toStringAsFixed(0)}%',
                delta: ReportFormat.percentDelta(
                  report.occupancyRate,
                  report.previousPeriod.occupancy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.trending_up_rounded,
                iconColor: colors.brandLight,
                label: 'Đơn giá TB',
                value: ReportFormat.vndShort(report.adr),
                fullValue: ReportFormat.vndFull(report.adr),
                delta: ReportFormat.percentDelta(
                  report.adr,
                  report.previousPeriod.adr,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                icon: Icons.book_rounded,
                iconColor: AppColors.gold500,
                label: 'Booking',
                value: '${report.totalBookings}',
                delta: ReportFormat.percentDelta(
                  report.totalBookings,
                  report.previousPeriod.bookings,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? fullValue;
  final double? delta;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.fullValue,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final deltaColor = ReportFormat.deltaColor(colors, delta);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const Spacer(),
              if (delta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ReportFormat.deltaIcon(delta),
                        size: 10,
                        color: deltaColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        ReportFormat.deltaLabel(delta),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: deltaColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
          if (fullValue != null && fullValue != value) ...[
            const SizedBox(height: 1),
            Text(
              fullValue!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Top rooms list ───────────────────────────────────────────────────────

class _TopRoomsList extends StatelessWidget {
  final List<TopRoom> rooms;
  const _TopRoomsList({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rooms.asMap().entries.map((e) {
          final isLast = e.key == rooms.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: _TopRoomRow(rank: e.key + 1, room: e.value),
          );
        }).toList(),
      ),
    );
  }
}

class _TopRoomRow extends StatelessWidget {
  final int rank;
  final TopRoom room;

  const _TopRoomRow({required this.rank, required this.room});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPodium = rank <= 3;
    final podiumColor = switch (rank) {
      1 => AppColors.gold500,
      2 => const Color(0xFFB0BEC5),
      3 => const Color(0xFFA1887F),
      _ => colors.textSecondary,
    };

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isPodium
                ? podiumColor.withValues(alpha: 0.18)
                : colors.bgSurfaceContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isPodium ? podiumColor : colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.name,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${room.bookings} booking · ${(room.occupancy * 100).toStringAsFixed(0)}% lấp đầy',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Flexible(
          flex: 0,
          child: Text(
            ReportFormat.vndShort(room.revenue),
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.textBrand,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      title,
      style: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.textTertiary,
      ),
    );
  }
}

// Recent bookings section.

class _PaginatedRecentBookings extends StatefulWidget {
  final List<BookingModel> bookings;
  const _PaginatedRecentBookings({super.key, required this.bookings});

  @override
  State<_PaginatedRecentBookings> createState() =>
      _PaginatedRecentBookingsState();
}

class _PaginatedRecentBookingsState extends State<_PaginatedRecentBookings> {
  static const _pageSize = 5;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.bookings.length;
    final totalPages = (total / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final pageItems = widget.bookings.sublist(start, end);

    return Column(
      children: [
        ...pageItems.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BookingRow(booking: e.value)
                  .animate(delay: (e.key * 40).ms)
                  .fadeIn(duration: 240.ms),
            )),
        if (totalPages > 1) ...[
          const SizedBox(height: 8),
          AppPaginationBar(
            currentPage: _page,
            totalPages: totalPages,
            onPrevious: _page > 0 ? () => setState(() => _page--) : null,
            onNext:
                _page < totalPages - 1 ? () => setState(() => _page++) : null,
          ),
        ],
      ],
    );
  }
}

class _BookingRow extends StatelessWidget {
  final BookingModel booking;
  const _BookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = AppHelpers.bookingStatusColor(booking.status.value);
    final initials =
        (booking.customerName ?? 'K').substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Không tên',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.propertyName} · ${booking.nights} đêm',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                booking.status.label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
