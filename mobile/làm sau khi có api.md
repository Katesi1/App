# Làm sau khi có API

## 1. Lịch Booking Tổng (BookingCalendarScreen)

### 1.1. Thay mock data bằng API
- File: `lib/features/bookings/views/booking_calendar_screen.dart`
- File shared: `lib/shared/widgets/calendar_grid_widget.dart` → `generateMockCalendarData()`
- Cần tạo provider trong `booking_controller.dart` gọi API lấy danh sách phòng + giá + trạng thái theo ngày
- Endpoint cần: lấy calendar grid data theo `category`, `propertyGroupId`, `dateRange`
- Data từ lịch tổng và lịch chủ nhà phải đồng bộ (cùng nguồn API)

### 1.2. Danh mục & nhóm property
- Mock: Villa (Sunferia, Harborbay, Grandbay), Homestay (3 mock), Khách sạn (3 mock)
- Cần API endpoint trả về danh sách property groups theo category
- Lịch tổng: hiển thị tất cả căn (public)
- Lịch chủ nhà: chỉ hiển thị căn của chủ nhà đang đăng nhập

### 1.3. Liên hệ admin qua Zalo (lịch tổng)
- File: `booking_calendar_screen.dart` → `_openZalo()`, `_callAdmin()`
- Thay số Zalo/SĐT mock (`0123456789`) bằng thông tin admin thật từ API
- Có thể lấy từ endpoint thông tin hệ thống hoặc config

### 1.4. Share lịch
- File: `booking_calendar_screen.dart` → `// TODO: Share functionality`
- Chụp screenshot grid hoặc export data
- Share qua các kênh (Zalo, Messenger, copy link...)

## 2. Lịch Chủ Nhà (OwnerCalendarScreen)

### 2.1. Thay mock data bằng API
- File: `lib/features/bookings/views/owner_calendar_screen.dart`
- Gọi API lấy chỉ các căn mà chủ nhà hiện tại sở hữu/quản lý
- Filter theo `userId` của user đang đăng nhập

### 2.2. Lock/Unlock phòng
- File: `owner_calendar_screen.dart` → `_toggleLock()`
- Hiện tại đang thay đổi state local (setState)
- Cần gọi API lock/unlock → sau đó `ref.invalidate()` provider để:
  - Cập nhật lịch chủ nhà
  - Đồng bộ lịch tổng (BookingCalendarScreen cũng sẽ reflect thay đổi)

## 3. Đồng bộ 2 lịch
- Lịch tổng và lịch chủ nhà phải dùng chung provider/API source
- Khi chủ nhà lock/unlock phòng trên lịch riêng → lịch tổng cũng cập nhật
- Cần invalidate provider chung sau mỗi mutation

## 4. Phân quyền

### 4.1. Chủ nhà (owner/staff)
- Vào từ: Quản lý → Lịch phòng (`/admin/owner-calendar`)
- Chỉ thấy căn do mình quản lý
- Có quyền lock/unlock (tap ô → dialog lock/mở)

### 4.2. Người xem (tất cả user)
- Vào từ: Bottom nav → Lịch (`/calendar`)
- Thấy tất cả căn (public)
- Tap ô → modal liên hệ admin qua Zalo/gọi điện
