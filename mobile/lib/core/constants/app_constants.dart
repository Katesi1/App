class AppConstants {
  static const String appName = 'Halong24h';
  static const int holdDurationMinutes = 30;
  static const int accessTokenKey = 900; // 15 phút

  // Storage keys
  static const String accessTokenKey_ = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.halongtravel.halong24h';
  static const String appStoreUrl =
      'https://apps.apple.com/app/halong24h/id000000000';
  static const String appDownloadPage = 'https://halong24h.vn/download';
}

enum UserRole { admin, owner, sale, customer }

extension UserRoleExtension on UserRole {
  int get value {
    switch (this) {
      case UserRole.admin:
        return 0;
      case UserRole.owner:
        return 1;
      case UserRole.sale:
        return 2;
      case UserRole.customer:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.owner:
        return 'Chủ nhà';
      case UserRole.sale:
        return 'Sale';
      case UserRole.customer:
        return 'Khách hàng';
    }
  }

  /// Role cho phép đăng ký (không cho ADMIN)
  static const registrableRoles = [
    UserRole.owner,
    UserRole.sale,
    UserRole.customer,
  ];

  /// Có phải role quản lý không (ADMIN + OWNER + SALE)
  bool get isManagement => this != UserRole.customer;

  static UserRole fromInt(int role) {
    switch (role) {
      case 0:
        return UserRole.admin;
      case 1:
        return UserRole.owner;
      case 2:
        return UserRole.sale;
      case 3:
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }
}

// 0=HOLD, 1=CONFIRMED, 2=CANCELLED, 3=COMPLETED
enum BookingStatus { hold, confirmed, cancelled, completed }

extension BookingStatusExtension on BookingStatus {
  int get value {
    switch (this) {
      case BookingStatus.hold:
        return 0;
      case BookingStatus.confirmed:
        return 1;
      case BookingStatus.cancelled:
        return 2;
      case BookingStatus.completed:
        return 3;
    }
  }

  static BookingStatus fromInt(int status) {
    switch (status) {
      case 1:
        return BookingStatus.confirmed;
      case 2:
        return BookingStatus.cancelled;
      case 3:
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
