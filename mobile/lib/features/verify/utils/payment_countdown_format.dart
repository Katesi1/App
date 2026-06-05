/// Format countdown phiên thanh toán (hỗ trợ TTL 24h).
String formatPaymentCountdown(Duration remaining) {
  if (remaining.isNegative || remaining.inSeconds <= 0) {
    return '00:00';
  }
  if (remaining.inHours > 0) {
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
  final m = remaining.inMinutes.toString().padLeft(2, '0');
  final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
