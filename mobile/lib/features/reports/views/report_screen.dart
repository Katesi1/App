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
import '../utils/report_period_utils.dart';
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
          _Header(params: params),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _PeriodSelector(params: params),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBody(
              context,
              ref,
              colors,
              params,
              reportAsync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
    ReportParams params,
    AsyncValue<ReportData> reportAsync,
  ) {
    if (reportAsync.isLoading && !reportAsync.hasValue) {
      return const ReportScreenSkeleton();
    }

    if (reportAsync.hasError && !reportAsync.hasValue) {
      return ErrorStateWidget(
        message: reportAsync.error.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(reportDataProvider(params)),
      );
    }

    final report = reportAsync.value!;

    return Stack(
      children: [
        RefreshIndicator(
          color: colors.brand,
          onRefresh: () async => ref.invalidate(reportDataProvider(params)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              if (params.period == ReportPeriod.custom &&
                  params.from != null &&
                  params.to != null) ...[
                _CustomRangeBanner(params: params),
                const SizedBox(height: AppSpacing.md),
              ],
              _SummaryStrip(params: params),
              const SizedBox(height: AppSpacing.md),
              _ReportSection(
                title: 'Chỉ số chính',
                subtitle: 'So sánh % với kỳ trước cùng độ dài',
                child: _KpiGrid(report: report),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportSection(
                title: 'Xu hướng',
                subtitle: 'Doanh thu, lấp đầy và booking theo ngày',
                child: RevenueTrendChart(points: report.revenueByDay),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportSection(
                title: 'Phân tích lưu trú',
                subtitle: 'Ngày trong tuần và độ dài lưu trú khách',
                child: Column(
                  children: [
                    DayOfWeekChart(data: report.dayOfWeekOccupancy),
                    const SizedBox(height: AppSpacing.md),
                    LengthOfStayChart(distribution: report.lengthOfStay),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportSection(
                title: 'Trạng thái booking',
                subtitle: 'Hold · Xác nhận · Hoàn thành · Huỷ',
                child: StatusDonutChart(
                  holdCount: report.holdCount,
                  confirmedCount: report.confirmedCount,
                  completedCount: report.completedCount,
                  cancelledCount: report.cancelledCount,
                ),
              ),
              if (report.topRooms.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ReportSection(
                  title: 'Top phòng doanh thu',
                  subtitle: 'Xếp hạng theo doanh thu trong kỳ',
                  child: _TopRoomsList(rooms: report.topRooms),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _ReportSection(
                title: 'Đánh giá khách',
                subtitle: 'Điểm trung bình và phản hồi gần đây',
                child: PropertyRatingsSection(
                  ratings: report.propertyRatings,
                  reviews: report.recentReviews,
                  overallAvgRating: report.overallAvgRating,
                  overallTotalReviews: report.overallTotalReviews,
                  overallDistribution: report.overallDistribution,
                ),
              ),
              if (!report.overallBreakdown.isEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                CriteriaBreakdownCard(breakdown: report.overallBreakdown),
              ],
              const SizedBox(height: AppSpacing.md),
              _ReportSection(
                title: 'Booking gần đây',
                subtitle: 'Danh sách mới nhất trong kỳ đã chọn',
                child: report.recentBookings.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.book_outlined,
                        message: 'Chưa có booking nào',
                      )
                    : _PaginatedRecentBookings(
                        key: ValueKey(report.recentBookings.length),
                        bookings: report.recentBookings,
                      ),
              ),
            ],
          ),
        ),
        if (reportAsync.isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: colors.brand,
              backgroundColor: colors.borderSubtle,
            ),
          ),
      ],
    );
  }
}

// ─── Summary strip ─────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final ReportParams params;

  const _SummaryStrip({required this.params});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final headline = ReportPeriodUtils.headline(params);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, size: 18, color: colors.brandLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan $headline',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Doanh thu từ booking xác nhận & hoàn thành. '
                  'Mũi tên so với kỳ trước.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textTertiary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms);
  }
}

// ─── Section wrapper ─────────────────────────────────────────────────────────

class _ReportSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ReportSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final ReportParams params;
  const _Header({required this.params});

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
                      'Thống kê ${ReportPeriodUtils.headline(params)}',
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
}

// ─── Custom range banner ────────────────────────────────────────────────────

class _CustomRangeBanner extends ConsumerWidget {
  final ReportParams params;

  const _CustomRangeBanner({required this.params});

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final range = await ReportPeriodUtils.pickCustomRange(
      context,
      initialFrom: params.from,
      initialTo: params.to,
    );
    if (!context.mounted || range == null) {
      return;
    }
    ref.read(selectedReportParamsProvider.notifier).state = params.copyWith(
      from: ReportPeriodUtils.dateOnly(range.start),
      to: ReportPeriodUtils.dateOnly(range.end),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final from = params.from!;
    final to = params.to!;
    final days = to.difference(from).inDays + 1;

    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => _edit(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: _DatePill(
                  label: 'Từ',
                  value: ReportPeriodUtils.formatDate(from),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: colors.brand,
                ),
              ),
              Expanded(
                child: _DatePill(
                  label: 'Đến',
                  value: ReportPeriodUtils.formatDate(to),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$days ngày',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.brand,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Period selector ───────────────────────────────────────────────────────

class _DatePill extends StatelessWidget {
  final String label;
  final String value;

  const _DatePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends ConsumerWidget {
  final ReportParams params;

  const _PeriodSelector({required this.params});

  Future<void> _onSelect(
    BuildContext context,
    WidgetRef ref,
    ReportPeriod period,
  ) async {
    if (period == ReportPeriod.custom) {
      final isCustom = params.period == ReportPeriod.custom;
      final range = await ReportPeriodUtils.pickCustomRange(
        context,
        initialFrom: isCustom ? params.from : null,
        initialTo: isCustom ? params.to : null,
      );
      if (!context.mounted || range == null) return;

      ref.read(selectedReportParamsProvider.notifier).state = ReportParams(
        period: ReportPeriod.custom,
        from: ReportPeriodUtils.dateOnly(range.start),
        to: ReportPeriodUtils.dateOnly(range.end),
      );
      return;
    }

    ref.read(selectedReportParamsProvider.notifier).state = ReportParams(
      period: period,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReportPeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = ReportPeriod.values[i];
          final selected = p == params.period;
          final isCustom = p == ReportPeriod.custom;
          return Material(
            color: selected ? colors.brand : colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: InkWell(
              onTap: () => _onSelect(context, ref, p),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  horizontal: isCustom && selected ? 12 : 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: selected ? colors.brand : colors.borderDefault,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCustom) ...[
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: selected
                            ? colors.textOnPrimary
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      p.label,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? colors.textOnPrimary : colors.textPrimary,
                      ),
                    ),
                  ],
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                )
                    .animate(delay: 0.ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.06, end: 0, duration: 260.ms),
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
                )
                    .animate(delay: 70.ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.06, end: 0, duration: 260.ms),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                )
                    .animate(delay: 140.ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.06, end: 0, duration: 260.ms),
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
                )
                    .animate(delay: 210.ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.06, end: 0, duration: 260.ms),
              ),
            ],
          ),
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
    final showFullValue = fullValue != null && fullValue != value;

    return SizedBox(
      height: 118,
      child: Container(
        width: double.infinity,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                  )
                else
                  const SizedBox(width: 28, height: 16),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: 11,
              child: showFullValue
                  ? Text(
                      fullValue!,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
            ),
          ],
        ),
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
        ...pageItems.asMap().entries.map((e) {
          final animated = Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BookingRow(booking: e.value),
          );
          if (e.key >= 5) return animated;
          return animated
              .animate(delay: (e.key * 50).ms)
              .fadeIn(duration: 240.ms);
        }),
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
