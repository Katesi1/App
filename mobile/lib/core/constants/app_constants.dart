class AppConstants {
  static const String appName = 'Halong24h';

  // Storage keys
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  /// SharedPreferences key for the in-progress KYC/subscription draft.
  /// Cleared on logout / account switch so one user's selected plan + KYC
  /// images never leak into another account (see VerifyFlowController).
  static const String verifyDraftKey = 'verify_flow_draft_v1';

  static const String appStoreUrl =
      'https://apps.apple.com/app/halong24h/id000000000';
  static const String appDownloadPage = 'https://halong24h.vn/download';

  // Support contact — shown on the KYC pending screen + anywhere the user
  // needs to reach the Halong24h team.
  static const String supportEmail = 'halong24h.team@gmail.com';
  static const String supportPhone = '0983692497';
}

// B2B app for homestay OWNER + SALE only. ADMIN exists on backend but cannot
// self-register through the app.
enum UserRole { admin, owner, sale }

extension UserRoleExtension on UserRole {
  int get value {
    switch (this) {
      case UserRole.admin:
        return 0;
      case UserRole.owner:
        return 1;
      case UserRole.sale:
        return 2;
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
    }
  }

  /// Roles users can self-register as (ADMIN is provisioned server-side only).
  static const registrableRoles = [UserRole.owner, UserRole.sale];

  static UserRole fromInt(int role) {
    switch (role) {
      case 0:
        return UserRole.admin;
      case 1:
        return UserRole.owner;
      case 2:
        return UserRole.sale;
      default:
        return UserRole.owner;
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
