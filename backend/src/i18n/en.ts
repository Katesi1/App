export const en = {
  // ─── Auth ───────────────────────────────────────────────────────────────────
  auth: {
    invalidCredentials: 'Email/phone or password is incorrect',
    invalidToken: 'Invalid token',
    invalidRefreshToken: 'Invalid refresh token',
    expiredRefreshToken: 'Refresh token is invalid or expired',
    accountDisabled: 'Account does not exist or has been disabled',
    invalidResetToken: 'Reset token is invalid or expired',
    loginSuccess: 'Login successful',
    refreshSuccess: 'Token refreshed successfully',
    logoutSuccess: 'Logout successful',
    profileSuccess: 'Profile retrieved successfully',
    forgotPasswordSuccess: 'Reset instructions sent successfully',
    resetPasswordSuccess: 'Password reset successfully',
  },

  // ─── Users ───────────────────────────────────────────────────────────────────
  users: {
    notFound: 'User not found',
    emailDuplicate: 'Email is already in use',
    phoneDuplicate: 'Phone number is already in use',
    cannotDeleteSelf: 'Cannot delete your own account',
    wrongPassword: 'Current password is incorrect',
    forbidden: 'You do not have permission to manage this user',
    listSuccess: 'User list retrieved successfully',
    getSuccess: 'User retrieved successfully',
    createSuccess: 'User created successfully',
    updateSuccess: 'User updated successfully',
    disableSuccess: 'User disabled successfully',
    changePasswordSuccess: 'Password changed successfully',
  },

  // ─── Properties ─────────────────────────────────────────────────────────────
  properties: {
    notFound: 'Property not found',
    forbidden: 'You do not have access to this property',
    listSuccess: 'Property list retrieved successfully',
    getSuccess: 'Property retrieved successfully',
    createSuccess: 'Property created successfully',
    updateSuccess: 'Property updated successfully',
    deleteSuccess: 'Property deleted successfully',
    statsSuccess: 'Property stats retrieved successfully',
  },

  // ─── Room Types ─────────────────────────────────────────────────────────────
  roomTypes: {
    notFound: 'Room type not found',
    nameDuplicate: 'Room type name already exists',
    hasRooms: 'Cannot delete room type that has rooms assigned',
    listSuccess: 'Room type list retrieved successfully',
    getSuccess: 'Room type retrieved successfully',
    createSuccess: 'Room type created successfully',
    updateSuccess: 'Room type updated successfully',
    deleteSuccess: 'Room type deleted successfully',
  },

  // ─── Amenities ──────────────────────────────────────────────────────────────
  amenities: {
    notFound: 'Amenity not found',
    nameDuplicate: 'Amenity name already exists',
    listSuccess: 'Amenity list retrieved successfully',
    createSuccess: 'Amenity created successfully',
    updateSuccess: 'Amenity updated successfully',
    deleteSuccess: 'Amenity deleted successfully',
  },

  // ─── Rooms ───────────────────────────────────────────────────────────────────
  rooms: {
    notFound: 'Room not found',
    imageNotFound: 'Image not found',
    hasActiveBookings: 'Cannot delete room with active bookings',
    maxImages: (max: number) => `Maximum ${max} images per room`,
    uploadSuccess: (count: number) => `${count} image(s) uploaded successfully`,
    forbiddenAdd: 'You do not have permission to add rooms to this property',
    forbidden: 'You do not have permission to manage this room',
    listSuccess: 'Room list retrieved successfully',
    getSuccess: 'Room retrieved successfully',
    createSuccess: 'Room created successfully',
    updateSuccess: 'Room updated successfully',
    deleteSuccess: 'Room deleted successfully',
    deleteImageSuccess: 'Image deleted successfully',
    setCoverSuccess: 'Cover image set successfully',
  },

  // ─── Customers ──────────────────────────────────────────────────────────────
  customers: {
    notFound: 'Customer not found',
    phoneDuplicate: 'Customer phone number already exists',
    hasActiveBookings: 'Cannot delete customer with active bookings',
    listSuccess: 'Customer list retrieved successfully',
    getSuccess: 'Customer retrieved successfully',
    createSuccess: 'Customer created successfully',
    updateSuccess: 'Customer updated successfully',
    deleteSuccess: 'Customer deleted successfully',
  },

  // ─── Bookings ────────────────────────────────────────────────────────────────
  bookings: {
    notFound: 'Booking not found',
    checkoutBeforeCheckin: 'Check-out date must be after check-in date',
    checkinInPast: 'Check-in date cannot be in the past',
    roomAlreadyBooked: 'Room is already booked for this period',
    roomOnHold: (minutes: number) => `Room is currently on hold, will be released in ${minutes} minute(s)`,
    exceedsCapacity: 'Guest count exceeds room capacity',
    onlyConfirmHold: 'Only bookings with HOLD status can be confirmed',
    onlyCheckinConfirmed: 'Only CONFIRMED bookings can be checked in',
    onlyCheckoutCheckedIn: 'Only CHECKED_IN bookings can be checked out',
    onlyDeleteHold: 'Only HOLD bookings can be deleted',
    alreadyCancelled: 'Booking has already been cancelled',
    cannotCancelCompleted: 'Cannot cancel a completed booking',
    cannotUpdateCompleted: 'Cannot update a completed or cancelled booking',
    invalidStatusTransition: 'Invalid status transition',
    forbiddenAccess: 'You do not have permission to access this booking',
    listSuccess: 'Booking list retrieved successfully',
    getSuccess: 'Booking retrieved successfully',
    holdSuccess: 'Room held successfully (30 minutes)',
    confirmSuccess: 'Booking confirmed successfully',
    checkinSuccess: 'Check-in successful',
    checkoutSuccess: 'Check-out successful',
    cancelSuccess: 'Booking cancelled successfully',
    updateSuccess: 'Booking updated successfully',
    deleteSuccess: 'Booking deleted successfully',
  },

  // ─── Payments ────────────────────────────────────────────────────────────────
  payments: {
    notFound: 'Payment not found',
    listSuccess: 'Payment list retrieved successfully',
    getSuccess: 'Payment retrieved successfully',
    createSuccess: 'Payment recorded successfully',
    updateSuccess: 'Payment status updated successfully',
  },

  // ─── Notifications ──────────────────────────────────────────────────────────
  notifications: {
    notFound: 'Notification not found',
    listSuccess: 'Notifications retrieved successfully',
    readSuccess: 'Notification marked as read',
    readAllSuccess: 'All notifications marked as read',
    deleteSuccess: 'Notification deleted successfully',
  },

  // ─── Reports ─────────────────────────────────────────────────────────────────
  reports: {
    revenueSuccess: 'Revenue report retrieved successfully',
    occupancySuccess: 'Occupancy report retrieved successfully',
    bookingsSummarySuccess: 'Bookings summary retrieved successfully',
    topRoomsSuccess: 'Top rooms report retrieved successfully',
    dashboardSuccess: 'Dashboard stats retrieved successfully',
  },
};
