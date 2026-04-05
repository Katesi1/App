import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized helper functions used across the app.
class AppHelpers {
  AppHelpers._();

  // ── Role helpers ──────────────────────────────────────────────────────────

  static String roleLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'STAFF':
        return 'Nhân viên';
      case 'CUSTOMER':
        return 'Khách hàng';
      // Migration: role cũ
      case 'OWNER':
        return 'Nhân viên';
      case 'SALE':
        return 'Nhân viên';
      default:
        return role ?? '';
    }
  }

  static Color roleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return AppColors.coral;
      case 'STAFF':
        return AppColors.ocean;
      case 'CUSTOMER':
        return AppColors.teal;
      // Migration: role cũ
      case 'OWNER':
      case 'SALE':
        return AppColors.ocean;
      default:
        return AppColors.ocean;
    }
  }

  // ── Booking status helpers ────────────────────────────────────────────────

  static Color bookingStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'HOLD':
        return AppColors.hold;
      case 'CONFIRMED':
        return AppColors.confirmed;
      case 'CANCELLED':
        return AppColors.cancelled;
      case 'COMPLETED':
        return AppColors.completed;
      default:
        return AppColors.primary;
    }
  }

  // ── Price formatting ──────────────────────────────────────────────────────

  static String formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}tr';
    }
    return '${(price / 1000).toStringAsFixed(0)}k';
  }

  static String formatPriceTotal(double pricePerNight, int nights) {
    final total = pricePerNight * nights;
    return formatPrice(total);
  }

  /// Hiển thị số KPI; 0 → "-" (tránh "0k" nhầm thành "Ok").
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
}
