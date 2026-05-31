class ApiConstants {
  static const String baseUrl = 'https://api.halong24h.com';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String googleLogin = '/auth/google';
  static const String appleLogin = '/auth/apple';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Users
  static const String users = '/users';
  static String userDetail(String id) => '/users/$id';

  // Properties (lodging unit — also the booking unit).
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

  // Property share (public link, no pricing data).
  static String propertyShare(String id) => '/properties/share/$id';

  // KYC (identity verification for OWNER).
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
  static const String paymentRenew = '/payments/renew';
  static const String paymentHistory = '/payments/history';
  static String paymentStatus(String sessionId) =>
      '/payments/$sessionId/status';
  static String paymentRefund(String sessionId) =>
      '/payments/$sessionId/refund';

  // Apple In-App Purchase — backend receives the StoreKit receipt, validates
  // with Apple's verifyReceipt / App Store Server API, and persists the
  // subscription against the user.
  static const String paymentAppleVerify = '/payments/apple/verify';

  // Admin KYC (ADMIN-only).
  static const String adminKycQueue = '/admin/kyc/queue';
  static String adminKycApprove(String id) =>
      '/admin/kyc/submissions/$id/approve';
  static String adminKycReject(String id) =>
      '/admin/kyc/submissions/$id/reject';

  // Calendar
  static const String calendarPublicGrid =
      '/calendar/public-grid'; // GET — public, no auth
  static const String calendarGrid =
      '/calendar/grid'; // GET — management, Bearer token.
  static const String calendarLock =
      '/calendar/lock'; // POST = lock, DELETE = unlock.
  static const String calendarSold =
      '/calendar/sold'; // PATCH = mark as sold.
  static const String calendarAdminContact = '/calendar/admin-contact';

  // Dashboard & Reports
  static const String dashboardStats = '/dashboard/stats';
  static const String reports = '/reports';

  // Staff (OWNER invites employees via email).
  static const String staffInvites = '/staff/invites';
  static String staffInviteDetail(String id) => '/staff/invites/$id';
  static String staffInviteVerify(String token) =>
      '/staff/invites/verify/$token';
  static const String staffInviteAccept = '/staff/invites/accept';
  static const String staff = '/staff';
  static String staffDetail(String userId) => '/staff/$userId';

  // App version metadata for force-update flow.
  // BE returns: { latestVersion, minSupportedVersion, releaseNotes, storeUrl{ ios } }
  static const String appVersion = '/app/version';

  // Devices (FCM token registration for push notifications).
  static const String devices = '/devices';
  static String deviceDetail(String token) => '/devices/$token';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Partner (X-Partner-Key header is required — passed via repository, never hardcoded).
  static const String partnerProperties = '/partner/properties';
  static String partnerPropertyDetail(String id) => '/partner/properties/$id';
  static String partnerPropertyAvailability(String id) =>
      '/partner/properties/$id/availability';
  static const String partnerBookings = '/partner/bookings';
  static String partnerBookingCancel(String id) =>
      '/partner/bookings/$id/cancel';
}
