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

  // Users
  static const String users = '/users';
  static String userDetail(String id) => '/users/$id';

  // Homestays
  static const String homestays = '/homestays';
  static String homestayDetail(String id) => '/homestays/$id';

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
  static String bookingCalendar(String roomId) => '/bookings/calendar/$roomId';

  // Customer bookings
  static const String customerHold = '/bookings/customer-hold';
  static const String myBookings = '/bookings/my';
  static String customerCancel(String id) => '/bookings/$id/customer-cancel';

  // Public rooms (cho customer)
  static const String roomsPublic = '/rooms/public';
}
