class AppConstants {
  static const String appName = 'Halong24h';
  static const int holdDurationMinutes = 30;
  static const int accessTokenKey = 900; // 15 phút

  // Storage keys
  static const String accessTokenKey_ = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // TODO: Cập nhật các link bên dưới khi app được publish lên store.
  // playStoreUrl: lấy từ Google Play Console → trang app → "Xem trên Google Play"
  // appStoreUrl: lấy từ App Store Connect → trang app → "App URL"
  // appDownloadPage: trang web riêng (nếu có) để redirect theo platform
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.halong24h.app';
  static const String appStoreUrl =
      'https://apps.apple.com/app/halong24h/id000000000';
  static const String appDownloadPage = 'https://halong24h.vn/download';
}

enum UserRole { admin, staff, customer }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.staff:
        return 'STAFF';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.customer:
        return 'Khách hàng';
    }
  }

  /// Role cho phép đăng ký (không cho ADMIN)
  static const registrableRoles = [UserRole.staff, UserRole.customer];

  /// Có phải role quản lý không (ADMIN + STAFF)
  bool get isManagement => this != UserRole.customer;

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'STAFF':
        return UserRole.staff;
      case 'CUSTOMER':
        return UserRole.customer;
      // Migration: map role cũ sang STAFF
      case 'OWNER':
      case 'SALE':
        return UserRole.staff;
      default:
        return UserRole.customer;
    }
  }
}

enum BookingStatus { hold, confirmed, cancelled, completed }

extension BookingStatusExtension on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.hold:
        return 'HOLD';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.completed:
        return 'COMPLETED';
    }
  }

  static BookingStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'COMPLETED':
        return BookingStatus.completed;
      default:
        return BookingStatus.hold;
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.hold:
        return 'Đang giữ';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.cancelled:
        return 'Đã huỷ';
      case BookingStatus.completed:
        return 'Hoàn thành';
    }
  }
}
