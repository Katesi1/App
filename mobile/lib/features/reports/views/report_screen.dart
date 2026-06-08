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

/// Ngày tối đa hợp lệ cho bộ lọc báo cáo = hôm nay theo giờ local (VN). BE đã
/// validate/aggregate `to` theo timezone VN (Asia/Ho_Chi_Minh) nên gửi ngày
/// local là chuẩn, không còn lệch ngày như khi cap theo UTC.
DateTime _reportMaxDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

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
                      onChanged: (p) async {
                        if (p == ReportPeriod.custom) {
                          await _pickCustomRange(context, ref, params);
                        } else {
                          ref
                              .read(selectedReportParamsProvider.notifier)
                              .state = params.copyWith(period: p);
                        }
                      },
                    ),
                    if (params.period == ReportPeriod.custom &&
                        params.from != null &&
                        params.to != null) ...[
                      const SizedBox(height: 10),
                      _CustomRangeChip(
                        from: params.from!,
                        to: params.to!,
                        onEdit: () => _pickCustomRange(context, ref, params),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _KpiGrid(report: report),
                    const SizedBox(height: AppSpacing.md),
                    RevenueTrendChart(points: report.revenueByDay)
                        .animate()
                        .fadeIn(delay: 220.ms, duration: 360.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: AppSpacing.md),
                    DayOfWeekChart(data: report.dayOfWeekOccupancy)
                        .animate()
                        .fadeIn(delay: 280.ms, duration: 360.ms),
                    const SizedBox(height: AppSpacing.md),
                    LengthOfStayChart(distribution: report.lengthOfStay)
                        .animate()
                        .fadeIn(delay: 320.ms, duration: 360.ms),
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

  /// Open the custom-range filter as a bottom sheet (no separate page). Only
  /// applies when the user actually picks a range (cancel → keep current).
  Future<void> _pickCustomRange(
    BuildContext context,
    WidgetRef ref,
    ReportParams params,
  ) async {
    final maxDate = _reportMaxDate();
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RangeFilterSheet(
        initialFrom: params.from ?? maxDate.subtract(const Duration(days: 7)),
        initialTo: params.to ?? maxDate,
      ),
    );
    if (picked == null) return;
    ref.read(selectedReportParamsProvider.notifier).state = params.copyWith(
      period: ReportPeriod.custom,
      from: DateTime(picked.start.year, picked.start.month, picked.start.day),
      to: DateTime(picked.end.year, picked.end.month, picked.end.day),
    );
  }
}

// ─── Custom range filter bottom sheet ────────────────────────────────────────

/// Date-range picker presented in-place as a bottom sheet so users filter the
/// report without leaving the screen. Quick presets + per-date dialogs.
class _RangeFilterSheet extends StatefulWidget {
  final DateTime initialFrom;
  final DateTime initialTo;

  const _RangeFilterSheet({required this.initialFrom, required this.initialTo});

  @override
  State<_RangeFilterSheet> createState() => _RangeFilterSheetState();
}

class _RangeFilterSheetState extends State<_RangeFilterSheet> {
  late DateTime _from = widget.initialFrom;
  late DateTime _to = widget.initialTo;

  String _d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  void _applyPreset(int days) {
    setState(() {
      _to = _reportMaxDate();
      _from = _to.subtract(Duration(days: days));
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final maxDate = _reportMaxDate();
    // initialDate phải nằm trong [firstDate, lastDate] — clamp tránh assert.
    final base = isFrom ? _from : _to;
    final initial = base.isAfter(maxDate) ? maxDate : base;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(maxDate.year - 3),
      lastDate: maxDate,
      helpText: isFrom ? 'Chọn ngày bắt đầu' : 'Chọn ngày kết thúc',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_from.isAfter(_to)) _to = _from;
      } else {
        _to = picked;
        if (_to.isBefore(_from)) _from = _to;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final days = _to.difference(_from).inDays + 1;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: colors.textBrand),
              const SizedBox(width: 8),
              Text(
                'Lọc theo thời gian',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close_rounded,
                    size: 20, color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick presets.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(label: '7 ngày qua', onTap: () => _applyPreset(6)),
              _PresetChip(label: '30 ngày qua', onTap: () => _applyPreset(29)),
              _PresetChip(label: '90 ngày qua', onTap: () => _applyPreset(89)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Từ ngày',
                  value: _d(_from),
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTile(
                  label: 'Đến ngày',
                  value: _d(_to),
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Khoảng $days ngày',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(
                DateTimeRange(start: _from, end: _to),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Áp dụng bộ lọc'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(
          begin: 0.08,
          end: 0,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: colors.brand.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textBrand,
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: colors.textBrand),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom range chip ──────────────────────────────────────────────────────

class _CustomRangeChip extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final VoidCallback onEdit;

  const _CustomRangeChip({
    required this.from,
    required this.to,
    required this.onEdit,
  });

  String _d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.brand.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded, size: 16, color: colors.textBrand),
            const SizedBox(width: 8),
            Text(
              '${_d(from)} → ${_d(to)}',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textBrand,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_outlined,
                size: 15, color: colors.textBrand),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

    final cards = <Widget>[
      _KpiCard(
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
      _KpiCard(
        icon: Icons.percent_rounded,
        iconColor: colors.brand,
        label: 'Lấp đầy',
        value: '${report.occupancyRate.toStringAsFixed(0)}%',
        delta: ReportFormat.percentDelta(
          report.occupancyRate,
          report.previousPeriod.occupancy,
        ),
      ),
      _KpiCard(
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
      _KpiCard(
        icon: Icons.book_rounded,
        iconColor: AppColors.gold500,
        label: 'Booking',
        value: '${report.totalBookings}',
        delta: ReportFormat.percentDelta(
          report.totalBookings,
          report.previousPeriod.bookings,
        ),
      ),
    ];

    // Stagger each card in (fade + slide) — max 2 effects per item.
    final animated = cards
        .asMap()
        .entries
        .map((e) => e.value
            .animate(delay: (e.key * 70).ms)
            .fadeIn(duration: 320.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic))
        .toList();

    // IntrinsicHeight + stretch so both cards in a row share the taller's
    // height. Each row contains one card with a `fullValue` line, so all four
    // cards end up the same height.
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: animated[0]),
              const SizedBox(width: 10),
              Expanded(child: animated[1]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: animated[2]),
              const SizedBox(width: 10),
              Expanded(child: animated[3]),
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
