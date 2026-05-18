import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../data/report_models.dart';
import 'report_format.dart';

/// 3 metrics that can be plotted on the trend chart.
enum TrendMetric { revenue, occupancy, bookings }

extension TrendMetricX on TrendMetric {
  String get label => switch (this) {
        TrendMetric.revenue => 'Doanh thu',
        TrendMetric.occupancy => 'Lấp đầy',
        TrendMetric.bookings => 'Booking',
      };
}

/// Line chart showing revenue / occupancy / bookings trends by day.
///
/// Uses `fl_chart`. Tap any point → tooltip with date + value.
class RevenueTrendChart extends StatefulWidget {
  final List<RevenuePoint> points;
  const RevenueTrendChart({super.key, required this.points});

  @override
  State<RevenueTrendChart> createState() => _RevenueTrendChartState();
}

class _RevenueTrendChartState extends State<RevenueTrendChart> {
  TrendMetric _metric = TrendMetric.revenue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (widget.points.isEmpty) {
      return _emptyState(colors);
    }

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
              Expanded(
                child: Text(
                  'Xu hướng ${_metric.label.toLowerCase()}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _MetricToggle(
                current: _metric,
                onChanged: (m) => setState(() => _metric = m),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(_buildChart(colors)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppColorScheme colors) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Chưa có dữ liệu xu hướng',
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          color: colors.textTertiary,
        ),
      ),
    );
  }

  LineChartData _buildChart(AppColorScheme colors) {
    final spots = <FlSpot>[];
    for (var i = 0; i < widget.points.length; i++) {
      final p = widget.points[i];
      final y = switch (_metric) {
        TrendMetric.revenue => p.revenue.toDouble() / 1000000, // tr
        TrendMetric.occupancy => p.occupancy * 100,
        TrendMetric.bookings => p.bookings.toDouble(),
      };
      spots.add(FlSpot(i.toDouble(), y));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;
    final yStep = ((maxY - minY) / 4).ceilToDouble();

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => colors.textPrimary,
          getTooltipItems: (spots) => spots.map((s) {
            final p = widget.points[s.x.toInt()];
            return LineTooltipItem(
              _tooltipText(p),
              GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yStep > 0 ? yStep : 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colors.borderSubtle,
          strokeWidth: 1,
          dashArray: const [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: yStep > 0 ? yStep : 1,
            getTitlesWidget: (value, _) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                _yAxisLabel(value),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 9,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            // Show every 5th date to avoid overlapping labels.
            interval: (widget.points.length / 5).ceilToDouble(),
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx < 0 || idx >= widget.points.length) {
                return const SizedBox.shrink();
              }
              final d = widget.points[idx].date;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${d.day}/${d.month}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 9,
                    color: colors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      minY: minY,
      maxY: maxY * 1.1,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: colors.brand,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 2.5,
              color: colors.brand,
              strokeColor: colors.bgSurface,
              strokeWidth: 1.5,
            ),
            checkToShowDot: (spot, _) {
              // Show dot every 3rd point to reduce clutter.
              return spot.x.toInt() % 3 == 0;
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.brand.withValues(alpha: 0.18),
                colors.brand.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _yAxisLabel(double value) {
    return switch (_metric) {
      TrendMetric.revenue => '${value.toStringAsFixed(0)}tr',
      TrendMetric.occupancy => '${value.toStringAsFixed(0)}%',
      TrendMetric.bookings => value.toStringAsFixed(0),
    };
  }

  String _tooltipText(RevenuePoint p) {
    final dateStr = '${p.date.day}/${p.date.month}';
    final value = switch (_metric) {
      TrendMetric.revenue => ReportFormat.vndShort(p.revenue),
      TrendMetric.occupancy => '${(p.occupancy * 100).toStringAsFixed(0)}%',
      TrendMetric.bookings => '${p.bookings} booking',
    };
    return '$dateStr · $value';
  }
}

class _MetricToggle extends StatelessWidget {
  final TrendMetric current;
  final ValueChanged<TrendMetric> onChanged;

  const _MetricToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TrendMetric.values.map((m) {
          final selected = m == current;
          return GestureDetector(
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? colors.bgSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
                border: selected
                    ? Border.all(color: colors.borderDefault)
                    : null,
              ),
              child: Text(
                m.label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.textPrimary : colors.textTertiary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
