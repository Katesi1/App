class ApiConstants {
  static const String baseUrl = 'http://103.183.118.148:3000';

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

  // Properties (cơ sở lưu trú)
  static const String properties = '/properties';
  static String propertyDetail(String id) => '/properties/$id';

  // Rooms
  static const String rooms = '/rooms';
  static String roomDetail(String id) => '/rooms/$id';
  static String roomImages(String id) => '/rooms/$id/images';
  static String roomImageDetail(String roomId, String imageId) =>
      '/rooms/$roomId/images/$imageId';
  static String roomImageCover(String roomId, String imageId) =>
      '/rooms/$roomId/images/$imageId/cover';
  static String roomPrices(String roomId) => '/rooms/$roomId/prices';

  // Bookings
  static const String bookings = '/bookings';
  static const String holdRoom = '/bookings/hold';
  static String bookingDetail(String id) => '/bookings/$id';
  static String bookingConfirm(String id) => '/bookings/$id/confirm';
  static String bookingCancel(String id) => '/bookings/$id/cancel';
  static String bookingUpdate(String id) => '/bookings/$id';
  static String bookingCalendar(String roomId) => '/bookings/calendar/$roomId';

  // Customer bookings
  static const String customerHold = '/bookings/customer-hold';
  static const String myBookings = '/bookings/my';
  static String customerCancel(String id) => '/bookings/$id/customer-cancel';

  // Public rooms (cho customer)
  static const String roomsPublic = '/rooms/public';

  // Calendar
  static const String calendarPropertyGroups = '/calendar/property-groups';
  static const String calendarGrid = '/calendar/grid';
  static const String calendarLock = '/calendar/lock';
  static const String calendarUnlock = '/calendar/unlock';
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
  static const String partnerRooms = '/partner/rooms';
  static String partnerRoomDetail(String id) => '/partner/rooms/$id';
  static String partnerRoomAvailability(String id) =>
      '/partner/rooms/$id/availability';
  static const String partnerBookings = '/partner/bookings';
  static String partnerBookingCancel(String id) =>
      '/partner/bookings/$id/cancel';
}
