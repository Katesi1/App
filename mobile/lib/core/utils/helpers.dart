import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized helper functions used across the app.
class AppHelpers {
  AppHelpers._();

  // ── Role helpers (0=ADMIN, 1=OWNER, 2=SALE, 3=CUSTOMER) ─────────────────

  static String roleLabel(int? role) {
    switch (role) {
      case 0:
        return 'Admin';
      case 1:
        return 'Chủ nhà';
      case 2:
        return 'Sale';
      case 3:
        return 'Khách hàng';
      default:
        return '';
    }
  }

  static Color roleColor(int? role) {
    switch (role) {
      case 0:
        return AppColors.coral;
      case 1:
        return AppColors.amber;
      case 2:
        return AppColors.ocean;
      case 3:
        return AppColors.teal;
      default:
        return AppColors.ocean;
    }
  }

  // ── Booking status helpers (0=HOLD, 1=CONFIRMED, 2=CANCELLED, 3=COMPLETED, 4=NO_SHOW)

  static Color bookingStatusColor(int? status) {
    switch (status) {
      case 0:
        return AppColors.hold;
      case 1:
        return AppColors.confirmed;
      case 2:
        return AppColors.cancelled;
      case 3:
        return AppColors.completed;
      case 4:
        return AppColors.amber;
      default:
        return AppColors.primary;
    }
  }

  // ── Price formatting ──────────────────────────────────────────────────────

  static String formatPrice(double price) {
    if (price >= 1000000) {
      final str = (price / 1000000).toStringAsFixed(1);
      // Bỏ ".0" thừa: 2.0tr → 2tr, giữ phần lẻ 2.5tr.
      return '${str.endsWith('.0') ? str.substring(0, str.length - 2) : str}tr';
    }
    return '${(price / 1000).toStringAsFixed(0)}k';
  }

  static String formatPriceTotal(double pricePerNight, int nights) {
    final total = pricePerNight * nights;
    return formatPrice(total);
  }

  /// Giá gọn nhưng CHÍNH XÁC (không làm tròn) cho ô lịch chật:
  ///   2.500.000 → "2tr5"   ·  2.550.000 → "2tr550"
  ///   2.000.000 → "2tr"    ·  2.050.000 → "2tr50"   ·  900.000 → "900k"
  /// Phần sau "tr" là số nghìn còn lại: bội của trăm nghìn rút gọn 1 chữ số
  /// (500→"5"), còn lại giữ nguyên số nghìn (550→"550").
  static String formatPriceCompact(double price) {
    if (price < 1000000) {
      return '${(price / 1000).round()}k';
    }
    final k = (price / 1000).round(); // tổng nghìn
    final tr = k ~/ 1000; // số triệu
    final rem = k % 1000; // nghìn còn lại 0..999
    if (rem == 0) {
      return '${tr}tr';
    }
    if (rem % 100 == 0) {
      return '${tr}tr${rem ~/ 100}';
    }
    return '${tr}tr$rem';
  }

  /// Giá đầy đủ có phân nhóm nghìn cho khối tiền chi tiết (booking detail,
  /// hoá đơn): 4000000 → "4.000.000 ₫". Khác `formatPrice` (rút gọn "4tr").
  static String formatVnd(double price) {
    final grouped = price.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$grouped ₫';
  }

  /// Display KPI number; 0 → "-" (avoids "0k" being misread as "Ok").
  static String formatIntOrDash(int value) => value == 0 ? '-' : '$value';

  static String formatPriceOrDash(double price) =>
      price == 0 ? '-' : formatPrice(price);

  // ── Vietnamese day of week ────────────────────────────────────────────────

  static String vietnameseDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  // ── Relative time (chat, notifications) ───────────────────────────────────

  /// Thời gian tương đối ngắn gọn: "now", "5 phút", "3 giờ", "2 ngày",
  /// rồi về dd/MM. Dùng cho inbox chat / danh sách thông báo.
  static String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    final local = time.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }
}
