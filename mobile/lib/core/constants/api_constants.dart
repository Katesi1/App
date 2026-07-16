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
  static const String userMeDataExport = '/users/me/data-export';
  static const String userMeConsents = '/users/me/consents';
  static const String userMeNotificationPreferences =
      '/users/me/notification-preferences';
  // Tài khoản nhận tiền OWNER (duyệt bởi ADMIN — BE §3.3)
  static const String userMeBank = '/users/me/bank';

  // Support & feedback
  static const String supportTickets = '/support/tickets';
  static String supportTicketDetail(String id) => '/support/tickets/$id';
  static String supportTicketReply(String id) => '/support/tickets/$id/reply';
  static const String feedback = '/feedback';

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
  static String bookingPaid(String id) => '/bookings/$id/paid';
  static String bookingCheckin(String id) => '/bookings/$id/checkin';
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

  /// Link preview công khai để OWNER chia sẻ 1 phòng qua Zalo/Messenger
  /// (trang web che giá bán). BE §4.14.
  static const String previewShareBase = 'https://preview.halong24h.com';
  static String propertyShareLink(String id) => '$previewShareBase/$id';

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
  static const String paymentQuote = '/payments/quote';
  static const String paymentInitiate = '/payments/initiate';
  static const String paymentActive = '/payments/active';
  static const String paymentRenew = '/payments/renew';
  static const String paymentHistory = '/payments/history';
  static String paymentStatus(String sessionId) =>
      '/payments/$sessionId/status';
  static String paymentCancel(String sessionId) =>
      '/payments/$sessionId/cancel';
  static String paymentRefund(String sessionId) =>
      '/payments/$sessionId/refund';

  // Admin Trial (chỉ ADMIN)
  static String adminUserSubscription(String id) =>
      '/admin/users/$id/subscription';
  static String adminUserTrial(String id) => '/admin/users/$id/trial';

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

  // Staff (OWNER mời nhân viên qua email)
  static const String staffInvites = '/staff/invites';
  static String staffInviteDetail(String id) => '/staff/invites/$id';

  /// `:code` — full token (64 hex) hoặc short code `HL-XXXXXX`.
  static String staffInviteVerify(String code) => '/staff/invites/verify/$code';
  static const String staffInviteAccept = '/staff/invites/accept';
  static const String staff = '/staff';
  static String staffDetail(String userId) => '/staff/$userId';

  // Reviews (đánh giá ở cấp Property — 6 tiêu chí 1-5 sao)
  static String propertyReviews(String propertyId) =>
      '/properties/$propertyId/reviews';
  static String propertyReviewReply(String propertyId, String reviewId) =>
      '/properties/$propertyId/reviews/$reviewId/reply';
  static String adminHideReview(String reviewId) => '/admin/reviews/$reviewId';

  // App version metadata cho force-update flow.
  // BE trả: { latestVersion, minSupportedVersion, releaseNotes, storeUrl{ ios, android } }
  static const String appVersion = '/app/version';

  // Devices (FCM token registration cho push notification)
  static const String devices = '/devices';
  static String deviceDetail(String token) => '/devices/$token';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Chat / Conversations (REST + WebSocket — xem API §17)
  static const String conversations = '/conversations';
  static const String conversationsUnreadCount = '/conversations/unread-count';
  static String conversationDetail(String id) => '/conversations/$id';
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';
  static String conversationRead(String id) => '/conversations/$id/read';
  static String conversationMessageDetail(String messageId) =>
      '/conversations/messages/$messageId';

  /// Namespace WebSocket socket.io (`wss://.../chat`). socket_io_client nối
  /// `baseUrl` + namespace `/chat`.
  static const String chatSocketNamespace = '/chat';

  // Partner (bắt buộc header X-Partner-Key — truyền qua repository, không hardcode)
  static const String partnerProperties = '/partner/properties';
  static String partnerPropertyDetail(String id) => '/partner/properties/$id';
  static String partnerPropertyAvailability(String id) =>
      '/partner/properties/$id/availability';
  static const String partnerBookings = '/partner/bookings';
  static String partnerBookingCancel(String id) =>
      '/partner/bookings/$id/cancel';
}
