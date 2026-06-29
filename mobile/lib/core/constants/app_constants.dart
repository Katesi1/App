class AppConstants {
  static const String appName = 'Halong24h';

  // Storage keys
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  /// SharedPreferences key for the in-progress KYC/subscription draft.
  /// Cleared on logout / account switch so one user's selected plan + KYC
  /// images never leak into another account (see VerifyFlowController).
  static const String verifyDraftKey = 'verify_flow_draft_v1';

  /// Prefix trang lịch phòng công khai của OWNER (web sale, không cần login).
  /// OWNER share `${zaloCalendarUrlPrefix}{ownerId}` để khách/SALE xem lịch +
  /// gọi Zalo. Domain prod cố định nên hardcode (xem spec Share link Zalo).
  static const String zaloCalendarUrlPrefix =
      'https://sale.halong24h.com/zalo-cal/';

  /// Build link lịch phòng công khai cho 1 OWNER.
  static String zaloCalendarUrl(String ownerId) =>
      '$zaloCalendarUrlPrefix$ownerId';

  // Support contact — shown on the KYC pending screen + anywhere the user
  // needs to reach the Halong24h team.
  static const String supportEmail = 'halong24h.team@gmail.com';
  static const String supportPhone = '0325992001';

  // Khung giờ hỗ trợ — hiển thị ở màn Trợ giúp.
  static const String supportHours = 'T2 - CN: 8:00 - 22:00';

  // Hotline tổng đài admin — dùng cho nút "Gọi điện cho Admin" ở lịch booking
  // (cố định, KHÁC với Zalo chủ nhà — Zalo dùng SĐT chủ nhà từ API).
  static const String adminHotline = '0976982240';

  // Website hoàn thiện hồ sơ + thanh toán gói dịch vụ (app KHÔNG bán gói/IAP).
  static const String websiteUrl = 'https://halong24h.vn';

  // Số ngày giữ tài khoản trước khi xoá vĩnh viễn (grace period) — dùng làm
  // mặc định hiển thị; giá trị thực BE trả về trong response xoá tài khoản.
  static const int accountDeletionGraceDays = 30;
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

// 0=HOLD, 1=CONFIRMED, 2=CANCELLED, 3=COMPLETED, 4=NO_SHOW
enum BookingStatus { hold, confirmed, cancelled, completed, noShow }

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
      case BookingStatus.noShow:
        return 4;
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
      case 4:
        return BookingStatus.noShow;
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
      case BookingStatus.noShow:
        return 'Không đến';
    }
  }
}
