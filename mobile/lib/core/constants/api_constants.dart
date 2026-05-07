class ApiConstants {
  // Ưu tiên inject qua --dart-define để tách môi trường release/staging/dev.
  // Mặc định giữ HTTP để tương thích backend hiện tại trong môi trường dev.
  // Release nên truyền --dart-define=API_BASE_URL=https://... để dùng TLS.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://103.183.118.148:3000',
  );

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String googleLogin = '/auth/google';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Users
  static const String users = '/users';
  static String userDetail(String id) => '/users/$id';

  // Properties (cơ sở lưu trú — đây cũng là booking unit)
  static const String properties = '/properties';
  static String propertyDetail(String id) => '/properties/$id';
  static String propertyImages(String id) => '/properties/$id/images';
  static String propertyImageDetail(String propertyId, String imageId) =>
      '/properties/$propertyId/images/$imageId';
  static String propertyImageCover(String propertyId, String imageId) =>
      '/properties/$propertyId/images/$imageId/cover';
  static String propertyPrices(String propertyId) =>
      '/properties/$propertyId/prices';

  // Bookings
  static const String bookings = '/bookings';
  static const String holdRoom = '/bookings/hold';
  static String bookingDetail(String id) => '/bookings/$id';
  static String bookingConfirm(String id) => '/bookings/$id/confirm';
  static String bookingCancel(String id) => '/bookings/$id/cancel';
  static String bookingUpdate(String id) => '/bookings/$id';
  static String bookingCalendar(String propertyId) =>
      '/bookings/calendar/$propertyId';

  // Customer bookings
  static const String customerHold = '/bookings/customer-hold';
  static const String myBookings = '/bookings/my-bookings';
  static String customerCancel(String id) => '/bookings/$id/customer-cancel';

  // Public properties (cho customer)
  static const String propertiesPublic = '/properties/public';

  // Property share (public, không trả giá)
  static String propertyShare(String id) => '/properties/share/$id';

  // KYC (verify identity cho OWNER)
  static const String kycUploadCccdFront = '/kyc/upload-cccd-front';
  static const String kycUploadCccdBack = '/kyc/upload-cccd-back';
  static const String kycUploadSelfie = '/kyc/upload-selfie';
  static const String kycSubmit = '/kyc/submit';
  static const String kycStatus = '/kyc/status';
  static String kycSubmissionDetail(String id) => '/kyc/submissions/$id';
  static String kycSubmissionResubmit(String id) =>
      '/kyc/submissions/$id/resubmit';

  // Billing
  static const String billingPlans = '/billing/plans';

  // Payment
  static const String paymentInitiate = '/payments/initiate';
  static String paymentStatus(String sessionId) =>
      '/payments/$sessionId/status';
  static String paymentRefund(String sessionId) =>
      '/payments/$sessionId/refund';

  // Admin KYC (chỉ ADMIN)
  static const String adminKycQueue = '/admin/kyc/queue';
  static String adminKycApprove(String id) =>
      '/admin/kyc/submissions/$id/approve';
  static String adminKycReject(String id) =>
      '/admin/kyc/submissions/$id/reject';

  // Calendar
  static const String calendarPublicGrid =
      '/calendar/public-grid'; // GET — public, no auth
  static const String calendarGrid =
      '/calendar/grid'; // GET — management, Bearer token
  static const String calendarLock =
      '/calendar/lock'; // POST = lock, DELETE = unlock
  static const String calendarSold =
      '/calendar/sold'; // PATCH = đánh dấu đã bán
  static const String calendarAdminContact = '/calendar/admin-contact';

  // Dashboard & Reports
  static const String dashboardStats = '/dashboard/stats';
  static const String reports = '/reports';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Partner (bắt buộc header X-Partner-Key — truyền qua repository, không hardcode)
  static const String partnerProperties = '/partner/properties';
  static String partnerPropertyDetail(String id) => '/partner/properties/$id';
  static String partnerPropertyAvailability(String id) =>
      '/partner/properties/$id/availability';
  static const String partnerBookings = '/partner/bookings';
  static String partnerBookingCancel(String id) =>
      '/partner/bookings/$id/cancel';
}
