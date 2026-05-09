import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color_scheme.dart';

/// Donut chart hiển thị phân bổ booking theo status.
///
/// Center hole = total bookings. Color: hold=warning, confirmed=success,
/// completed=brandLight, cancelled=error.
class StatusDonutChart extends StatelessWidget {
  final int holdCount;
  final int confirmedCount;
  final int completedCount;
  final int cancelledCount;

  const StatusDonutChart({
    super.key,
    required this.holdCount,
    required this.confirmedCount,
    required this.completedCount,
    required this.cancelledCount,
  });

  int get _total => holdCount + confirmedCount + completedCount + cancelledCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final segments = <_StatusSegment>[
      _StatusSegment('Đang giữ', holdCount, colors.warning),
      _StatusSegment('Đã xác nhận', confirmedCount, colors.success),
      _StatusSegment('Hoàn thành', completedCount, colors.brandLight),
      _StatusSegment('Đã huỷ', cancelledCount, colors.error),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Donut bên trái
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _total == 0
                    ? Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.borderDefault,
                            width: 12,
                          ),
                        ),
                      )
                    : PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                          sections: segments
                              .where((s) => s.count > 0)
                              .map((s) => PieChartSectionData(
                                    value: s.count.toDouble(),
                                    color: s.color,
                                    radius: 16,
                                    showTitle: false,
                                  ))
                              .toList(),
                        ),
                      ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_total',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'booking',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Legend bên phải
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: segments
                  .map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: _LegendRow(
                          label: s.label,
                          count: s.count,
                          color: s.color,
                          total: _total,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSegment {
  final String label;
  final int count;
  final Color color;
  const _StatusSegment(this.label, this.count, this.color);
}

class _LegendRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int total;

  const _LegendRow({
    required this.label,
    required this.count,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = total == 0 ? 0 : (count / total * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '· $pct%',
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
