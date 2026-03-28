# Làm sau khi có API

## 1. Lịch Booking - Grid Calendar

### 1.1. Thay mock data bằng API
- File: `lib/features/bookings/views/booking_calendar_screen.dart`
- Hiện tại dùng `_generateMockData()` tạo data giả (rooms, prices, status)
- Cần tạo provider trong `booking_controller.dart` gọi API lấy danh sách phòng + giá + trạng thái theo ngày
- Endpoint cần: lấy calendar grid data theo `category`, `propertyGroupId`, `dateRange`

### 1.2. Danh mục & nhóm property
- Mock: Villa (Sunferia, Harborbay, Grandbay), Homestay (3 mock), Khách sạn (3 mock)
- Cần API endpoint trả về danh sách property groups theo category
- Filter theo user: người tạo chỉ thấy căn của mình, admin/staff thấy tất cả

### 1.3. Tap ô = lock/unlock phòng
- File: `booking_calendar_screen.dart` dòng `// TODO: lock/unlock room`
- Khi tap vào ô trống → gọi API giữ phòng (hold)
- Khi tap vào ô đang giữ (của mình) → gọi API mở khoá (cancel hold)
- Cần xác nhận trước khi thực hiện (dialog)

### 1.4. Share lịch
- File: `booking_calendar_screen.dart` dòng `// TODO: Share functionality`
- Chụp screenshot grid hoặc export data
- Share qua các kênh (Zalo, Messenger, copy link...)

## 2. Phân quyền xem lịch

### 2.1. Người tạo (owner/staff)
- Chỉ thấy các căn do mình quản lý
- Có quyền lock/unlock phòng

### 2.2. Người xem (customer)
- Thấy tất cả căn (public)
- Chỉ xem, không lock/unlock
- Có thể chuyển sang flow đặt phòng khi tap ô trống
