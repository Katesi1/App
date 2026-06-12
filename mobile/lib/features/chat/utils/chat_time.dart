import 'package:intl/intl.dart';

/// Format thời gian cho UI chat. Gom về 1 nơi để inbox + bubble dùng chung.
class ChatTime {
  ChatTime._();

  /// Nhãn ngắn cho inbox: "5 phút", "Hôm qua", "12/06" hoặc "12/06/25".
  static String inboxLabel(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24 && now.day == time.day) {
      return DateFormat('HH:mm').format(time);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day) {
      return 'Hôm qua';
    }
    if (now.year == time.year) return DateFormat('dd/MM').format(time);
    return DateFormat('dd/MM/yy').format(time);
  }

  /// Giờ:phút cho timestamp dưới mỗi bubble.
  static String messageTime(DateTime time) => DateFormat('HH:mm').format(time);

  /// Nhãn phân cách ngày giữa các nhóm tin.
  static String daySeparator(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year &&
        now.month == time.month &&
        now.day == time.day) {
      return 'Hôm nay';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day) {
      return 'Hôm qua';
    }
    return DateFormat('dd/MM/yyyy').format(time);
  }

  /// True nếu 2 thời điểm khác ngày (để chèn separator).
  static bool isDifferentDay(DateTime a, DateTime b) =>
      a.year != b.year || a.month != b.month || a.day != b.day;
}
