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
      case 'OWNER':
        return 'Chủ nhà';
      case 'SALE':
        return 'Sale';
      default:
        return role ?? '';
    }
  }

  static Color roleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return AppColors.coral;
      case 'OWNER':
        return AppColors.completed;
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

  // ── Vietnamese day of week ────────────────────────────────────────────────

  static String vietnameseDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ nhật';
      default:
        return '';
    }
  }
}
