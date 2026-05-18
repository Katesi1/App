/// Format helpers specific to the verify flow.
///
/// Kept separate from `core/utils/helpers.dart` because:
/// - Verify uses the full "23.602.000đ" format (with thousands dots), which
///   differs from `AppHelpers.formatPrice` (truncates to "23.6tr").
/// - Verify needs a short format for plan cards ("2.985K", "26.8M") + full
///   format for order summary + CTA buttons.
class VerifyFormat {
  VerifyFormat._();

  /// Full format "23.602.000đ" — used for order summary and CTA buttons.
  static String priceVND(int amount) {
    final s = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final sign = amount < 0 ? '-' : '';
    return '$sign${buf.toString()}đ';
  }

  /// Short format "2.985.000đ" → "2.985K" or "23.602.000đ" → "23.6M".
  /// Used for plan card prices (16px header).
  static String priceShort(int amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      // 23.602.000 → "23.6M" ; 2.985.000 → "2.99M"
      return '${m.toStringAsFixed(m >= 10 ? 1 : 2)}M';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return '${k.toStringAsFixed(0)}K';
    }
    return '$amountđ';
  }

  /// "27/04/2026"
  static String dateVN(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year}';

  /// "27 / 04 / 2026" — used for the trial start date (signature pattern).
  static String dateSpaced(DateTime d) =>
      '${_two(d.day)} / ${_two(d.month)} / ${d.year}';

  /// "14:32" — short time.
  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// Trial countdown: ">24h" → "X ngày Yh", "<24h" → "Xh Y phút".
  static String countdown(Duration d) {
    if (d.isNegative) return 'Đã hết';
    if (d.inDays > 0) {
      final h = d.inHours % 24;
      return '${d.inDays} ngày ${h}h';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h $m phút';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
