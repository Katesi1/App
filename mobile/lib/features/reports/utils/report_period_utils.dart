import 'package:flutter/material.dart';

import '../controllers/report_controller.dart';
import '../views/widgets/report_date_range_sheet.dart';

/// Helpers cho chọn kỳ báo cáo — preset + custom date range.
class ReportPeriodUtils {
  ReportPeriodUtils._();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Mở date range picker. Trả `null` nếu user huỷ.
  static Future<DateTimeRange?> pickCustomRange(
    BuildContext context, {
    DateTime? initialFrom,
    DateTime? initialTo,
  }) async {
    final today = dateOnly(DateTime.now());
    final end = initialTo != null ? dateOnly(initialTo) : today;
    final start = initialFrom != null
        ? dateOnly(initialFrom)
        : end.subtract(const Duration(days: 29));

    final safeEnd = end.isAfter(today) ? today : end;
    final safeStart = start.isAfter(safeEnd)
        ? safeEnd.subtract(const Duration(days: 29))
        : start;

    return ReportDateRangeSheet.show(
      context,
      initialFrom: safeStart,
      initialTo: safeEnd,
    );
  }

  /// `01/06/2026 – 30/06/2026`
  static String formatRange(DateTime from, DateTime to) {
    return '${formatDate(from)} – ${formatDate(to)}';
  }

  static String formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  /// Tiêu đề header / summary theo kỳ đã chọn.
  static String headline(ReportParams params) {
    if (params.period == ReportPeriod.custom &&
        params.from != null &&
        params.to != null) {
      return formatRange(params.from!, params.to!);
    }
    return params.period.label.toLowerCase();
  }

  static bool paramsNeedCustomRange(ReportParams params) =>
      params.period == ReportPeriod.custom &&
      (params.from == null || params.to == null);
}
