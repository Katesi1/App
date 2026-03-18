class AppConstants {
  static const String appName = 'Homestay Manager';
  static const int holdDurationMinutes = 30;
  static const int accessTokenKey = 900; // 15 phút

  // Storage keys
  static const String accessTokenKey_ = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
}

enum UserRole { admin, owner, sale }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.owner:
        return 'OWNER';
      case UserRole.sale:
        return 'SALE';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'OWNER':
        return UserRole.owner;
      default:
        return UserRole.sale;
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
