import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/report_models.dart';

// ════════════════════════════════════════════════════════════════════════════
// 1. Criteria breakdown (6 criteria in ratings section).
// ════════════════════════════════════════════════════════════════════════════

class CriteriaBreakdownCard extends StatelessWidget {
  final RatingBreakdown breakdown;

  const CriteriaBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (breakdown.isEmpty) return const SizedBox.shrink();

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
          Text(
            'Tiêu chí đánh giá',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _CriteriaRow(label: item.label, score: item.score),
              )),
        ],
      ),
    );
  }
}

class _CriteriaRow extends StatelessWidget {
  final String label;
  final double score; // 0..5

  const _CriteriaRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = (score / 5).clamp(0.0, 1.0);
    final barColor =
        score >= 4.5 ? colors.success : (score >= 3.5 ? AppColors.gold500 : colors.warning);

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: colors.bgSurfaceContainer,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 2. Length-of-stay histogram (4 buckets: 1 / 2-3 / 4-7 / 8+ nights).
// ════════════════════════════════════════════════════════════════════════════

class LengthOfStayChart extends StatelessWidget {
  final LengthOfStayDistribution distribution;

  const LengthOfStayChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final buckets = distribution.buckets;
    final total = distribution.total;

    if (total == 0) {
      return _emptyState(colors, 'Chưa có dữ liệu length of stay');
    }

    final maxCount =
        buckets.map((b) => b.count).reduce((a, b) => a > b ? a : b);

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
          Text(
            'Thời gian lưu trú',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Phân bổ booking theo số đêm',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.textPrimary,
                    getTooltipItem: (group, _, rod, __) {
                      final b = buckets[group.x.toInt()];
                      final pct = (b.count / total * 100).round();
                      return BarTooltipItem(
                        '${b.count} booking · $pct%',
                        GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxCount / 3).ceilToDouble().clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.borderSubtle,
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            buckets[idx].label,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: buckets.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.count.toDouble(),
                        color: colors.brand,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxCount.toDouble() * 1.2,
                          color: colors.bgSurfaceContainer.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppColorScheme colors, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          color: colors.textTertiary,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 3. Day-of-week occupancy heatmap (7 cells Mon-Sun, intensity = occupancy).
// ════════════════════════════════════════════════════════════════════════════

class DayOfWeekChart extends StatelessWidget {
  final DayOfWeekOccupancy data;

  const DayOfWeekChart({super.key, required this.data});

  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data.values;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final hottestIdx = values.indexOf(maxV);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lấp đầy theo ngày trong tuần',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đậm hơn = lấp đầy cao hơn',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 12, color: AppColors.gold500),
                    const SizedBox(width: 4),
                    Text(
                      'Đỉnh: ${_labels[hottestIdx]}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                  child: _DayCell(
                    label: _labels[i],
                    value: values[i],
                    isPeak: i == hottestIdx,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final bool isPeak;

  const _DayCell({
    required this.label,
    required this.value,
    required this.isPeak,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Map occupancy 0..1 → alpha on brand color (0.1 → 0.95).
    final alpha = 0.1 + value * 0.85;
    final pct = (value * 100).round();

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: colors.brand.withValues(alpha: alpha.clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(10),
            border: isPeak
                ? Border.all(color: AppColors.gold500, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$pct%',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: value > 0.5 ? Colors.white : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
