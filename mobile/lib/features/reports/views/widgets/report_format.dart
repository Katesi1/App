import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';

class ReportFormat {
  ReportFormat._();

  /// Computes % delta between current vs previous. Returns `null` if
  /// previous == 0 (no baseline for comparison).
  static double? percentDelta(num current, num previous) {
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

  /// Format short VND: 1.500.000 → "1.5tr", 850000 → "850k", 99000 → "99k".
  static String vndShort(num? value) {
    final v = (value ?? 0).round();
    if (v == 0) return '0₫';
    if (v >= 1000000000) {
      final billions = v / 1000000000;
      return '${_trimZero(billions)} tỷ';
    }
    if (v >= 1000000) {
      final millions = v / 1000000;
      return '${_trimZero(millions)}tr';
    }
    if (v >= 1000) {
      final thousands = v / 1000;
      return '${_trimZero(thousands)}k';
    }
    return '$v₫';
  }

  /// Full VND format with thousand separators. 1500000 → "1.500.000 ₫".
  static String vndFull(num? value) {
    final v = (value ?? 0).round();
    final str = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '${buf.toString()} ₫';
  }

  /// Trims trailing `.0` for integers (e.g. 1.0tr → 1tr, 1.5tr → 1.5tr).
  static String _trimZero(double v) {
    final fixed = v.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  /// Color for delta % — green if positive, red if negative.
  static Color deltaColor(AppColorScheme colors, double? delta) {
    if (delta == null || delta == 0) return colors.textTertiary;
    return delta > 0 ? colors.success : colors.error;
  }

  /// Icon cho delta — arrow up / down / dash.
  static IconData deltaIcon(double? delta) {
    if (delta == null || delta == 0) return Icons.remove;
    return delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
  }

  /// Formats delta % as "↑ 12.3%" / "↓ 5.0%" / "—".
  static String deltaLabel(double? delta) {
    if (delta == null) return '—';
    final abs = delta.abs().toStringAsFixed(1);
    final stripped = abs.endsWith('.0') ? abs.substring(0, abs.length - 2) : abs;
    return '$stripped%';
  }
}
