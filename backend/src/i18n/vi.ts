export const vi = {
  // ─── Auth ───────────────────────────────────────────────────────────────────
  auth: {
    invalidCredentials: 'Email/SDT hoac mat khau khong dung',
    invalidToken: 'Token khong hop le',
    invalidRefreshToken: 'Refresh token khong hop le',
    expiredRefreshToken: 'Refresh token khong hop le hoac da het han',
    accountDisabled: 'Tai khoan khong ton tai hoac da bi vo hieu hoa',
    invalidResetToken: 'Reset token khong hop le hoac da het han',
    loginSuccess: 'Dang nhap thanh cong',
    refreshSuccess: 'Refresh token thanh cong',
    logoutSuccess: 'Dang xuat thanh cong',
    profileSuccess: 'Lay thong tin thanh cong',
    forgotPasswordSuccess: 'Da gui huong dan reset mat khau',
    resetPasswordSuccess: 'Dat lai mat khau thanh cong',
  },

  // ─── Users ───────────────────────────────────────────────────────────────────
  users: {
    notFound: 'Nguoi dung khong ton tai',
    emailDuplicate: 'Email da duoc su dung',
    phoneDuplicate: 'So dien thoai da duoc su dung',
    cannotDeleteSelf: 'Khong the xoa tai khoan cua chinh minh',
    wrongPassword: 'Mat khau hien tai khong dung',
    forbidden: 'Ban khong co quyen quan ly nguoi dung nay',
    listSuccess: 'Lay danh sach nguoi dung thanh cong',
    getSuccess: 'Lay thong tin nguoi dung thanh cong',
    createSuccess: 'Tao nguoi dung thanh cong',
    updateSuccess: 'Cap nhat nguoi dung thanh cong',
    disableSuccess: 'Vo hieu hoa nguoi dung thanh cong',
    changePasswordSuccess: 'Doi mat khau thanh cong',
  },

  // ─── Properties ─────────────────────────────────────────────────────────────
  properties: {
    notFound: 'Co so luu tru khong ton tai',
    forbidden: 'Ban khong co quyen truy cap co so nay',
    listSuccess: 'Lay danh sach co so thanh cong',
    getSuccess: 'Lay thong tin co so thanh cong',
    createSuccess: 'Tao co so thanh cong',
    updateSuccess: 'Cap nhat co so thanh cong',
    deleteSuccess: 'Xoa co so thanh cong',
    statsSuccess: 'Lay thong ke co so thanh cong',
  },

  // ─── Room Types ─────────────────────────────────────────────────────────────
  roomTypes: {
    notFound: 'Loai phong khong ton tai',
    nameDuplicate: 'Ten loai phong da ton tai',
    hasRooms: 'Khong the xoa loai phong dang co phong su dung',
    listSuccess: 'Lay danh sach loai phong thanh cong',
    getSuccess: 'Lay thong tin loai phong thanh cong',
    createSuccess: 'Tao loai phong thanh cong',
    updateSuccess: 'Cap nhat loai phong thanh cong',
    deleteSuccess: 'Xoa loai phong thanh cong',
  },

  // ─── Amenities ──────────────────────────────────────────────────────────────
  amenities: {
    notFound: 'Tien nghi khong ton tai',
    nameDuplicate: 'Ten tien nghi da ton tai',
    listSuccess: 'Lay danh sach tien nghi thanh cong',
    createSuccess: 'Tao tien nghi thanh cong',
    updateSuccess: 'Cap nhat tien nghi thanh cong',
    deleteSuccess: 'Xoa tien nghi thanh cong',
  },

  // ─── Rooms ───────────────────────────────────────────────────────────────────
  rooms: {
    notFound: 'Phong khong ton tai',
    imageNotFound: 'Anh khong ton tai',
    hasActiveBookings: 'Khong the xoa phong dang co booking',
    maxImages: (max: number) => `Toi da ${max} anh moi phong`,
    uploadSuccess: (count: number) => `Upload ${count} anh thanh cong`,
    forbiddenAdd: 'Ban khong co quyen them phong vao co so nay',
    forbidden: 'Ban khong co quyen thao tac phong nay',
    listSuccess: 'Lay danh sach phong thanh cong',
    getSuccess: 'Lay thong tin phong thanh cong',
    createSuccess: 'Tao phong thanh cong',
    updateSuccess: 'Cap nhat phong thanh cong',
    deleteSuccess: 'Xoa phong thanh cong',
    deleteImageSuccess: 'Xoa anh thanh cong',
    setCoverSuccess: 'Dat anh cover thanh cong',
  },

  // ─── Customers ──────────────────────────────────────────────────────────────
  customers: {
    notFound: 'Khach hang khong ton tai',
    phoneDuplicate: 'So dien thoai khach da ton tai',
    hasActiveBookings: 'Khong the xoa khach dang co booking',
    listSuccess: 'Lay danh sach khach thanh cong',
    getSuccess: 'Lay thong tin khach thanh cong',
    createSuccess: 'Tao ho so khach thanh cong',
    updateSuccess: 'Cap nhat khach thanh cong',
    deleteSuccess: 'Xoa khach thanh cong',
  },

  // ─── Bookings ────────────────────────────────────────────────────────────────
  bookings: {
    notFound: 'Booking khong ton tai',
    checkoutBeforeCheckin: 'Ngay check-out phai sau ngay check-in',
    checkinInPast: 'Ngay check-in khong the trong qua khu',
    roomAlreadyBooked: 'Phong da duoc dat trong khoang thoi gian nay',
    roomOnHold: (minutes: number) => `Phong dang duoc giu, con ${minutes} phut nua se tu dong huy`,
    exceedsCapacity: 'So khach vuot qua suc chua phong',
    onlyConfirmHold: 'Chi co the xac nhan booking dang o trang thai HOLD',
    onlyCheckinConfirmed: 'Chi co the check-in booking da CONFIRMED',
    onlyCheckoutCheckedIn: 'Chi co the check-out booking da CHECKED_IN',
    onlyDeleteHold: 'Chi co the xoa booking o trang thai HOLD',
    alreadyCancelled: 'Booking da bi huy truoc do',
    cannotCancelCompleted: 'Khong the huy booking da hoan thanh',
    cannotUpdateCompleted: 'Khong the cap nhat booking da hoan thanh hoac da huy',
    invalidStatusTransition: 'Chuyen trang thai khong hop le',
    forbiddenAccess: 'Ban khong co quyen truy cap booking nay',
    listSuccess: 'Lay danh sach booking thanh cong',
    getSuccess: 'Lay thong tin booking thanh cong',
    holdSuccess: 'Giu phong thanh cong (30 phut)',
    confirmSuccess: 'Xac nhan booking thanh cong',
    checkinSuccess: 'Check-in thanh cong',
    checkoutSuccess: 'Check-out thanh cong',
    cancelSuccess: 'Huy booking thanh cong',
    updateSuccess: 'Cap nhat booking thanh cong',
    deleteSuccess: 'Xoa booking thanh cong',
  },

  // ─── Payments ────────────────────────────────────────────────────────────────
  payments: {
    notFound: 'Giao dich khong ton tai',
    listSuccess: 'Lay danh sach thanh toan thanh cong',
    getSuccess: 'Lay thong tin giao dich thanh cong',
    createSuccess: 'Ghi nhan thanh toan thanh cong',
    updateSuccess: 'Cap nhat trang thai thanh toan thanh cong',
  },

  // ─── Notifications ──────────────────────────────────────────────────────────
  notifications: {
    notFound: 'Thong bao khong ton tai',
    listSuccess: 'Lay danh sach thong bao thanh cong',
    readSuccess: 'Danh dau da doc',
    readAllSuccess: 'Danh dau tat ca da doc',
    deleteSuccess: 'Xoa thong bao thanh cong',
  },

  // ─── Reports ─────────────────────────────────────────────────────────────────
  reports: {
    revenueSuccess: 'Lay bao cao doanh thu thanh cong',
    occupancySuccess: 'Lay bao cao cong suat thanh cong',
    bookingsSummarySuccess: 'Lay tong hop booking thanh cong',
    topRoomsSuccess: 'Lay bao cao top phong thanh cong',
    dashboardSuccess: 'Lay thong ke dashboard thanh cong',
  },
};
