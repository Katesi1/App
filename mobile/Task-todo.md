# Task Todo — Homestay Management App (Flutter Mobile)

> Cập nhật: 2026-03-17
> Đánh dấu `[x]` khi hoàn thành task.

---

## THÔNG TIN DỰ ÁN

| | |
|---|---|
| **Base URL** | `http://103.183.118.148:3000/api` |
| **Swagger UI** | `http://103.183.118.148:3000/index.html` |
| **Admin phone** | `Admin` |
| **Admin password** | `Abcd@1234` |
| **API Docs** | `API_DOCUMENTATION.md` |

---

## ⚠️ LỖI PHÁT HIỆN QUA API DOCS (cần fix ngay)

| # | Vấn đề | File | Ghi chú |
|---|--------|------|---------|
| 🔴 | Base URL sai port | `api_constants.dart` | Code: `:80/api` → Đúng: `:3000/api` |
| 🔴 | BookingStatus enum sai case | `app_constants.dart` | Code: lowercase `hold` → API trả: `HOLD` (uppercase) |
| 🟡 | Thiếu endpoint `GET /users/:id` | `api_constants.dart` | Cần thêm để fix `_loadUser()` |
| 🟡 | Price endpoint path sai | `api_constants.dart` | Cần `/rooms/:id/prices` riêng |
| 🟡 | Calendar endpoint path sai | `api_constants.dart` | API: `/bookings/calendar/:roomId?year=&month=` |

---

## PHASE 0 — SETUP & INFRASTRUCTURE

- [x] **P0-1** Sửa `ApiConstants.baseUrl` từ `:80` → `:3000/api`
- [x] **P0-2** `BookingStatus` enum đã đúng — `fromString()` dùng `toUpperCase()`, không cần fix
- [x] **P0-3** Cập nhật `ApiConstants`: thêm 9 endpoints còn thiếu (userDetail, roomPrices, bookingCalendar, confirm, cancel...)
- [x] **P0-4** Thêm packages: `flutter_animate 4.5.2`, `animations 2.1.1`, `lottie 3.3.2`, `google_fonts 6.3.3`
- [x] **P0-5** Tách file: `app_colors.dart` + `app_spacing.dart` + `app_theme.dart` (M3 light/dark) + `index.dart` barrel
- [x] **P0-6** Tạo `theme_provider.dart`: `ThemeNotifier` + `themeProvider` + lưu vào `SharedPreferences`
- [x] **P0-7** Cập nhật `main.dart`: `theme`, `darkTheme`, `themeMode` từ `themeProvider`

---

## PHASE 1 — STATE MANAGEMENT (PROVIDERS)

- [x] **P1-1** Tạo `homestay_provider.dart`: `homestayListProvider`, `homestayDetailProvider`, `homestayActionsProvider`
- [x] **P1-2** Tạo `booking_provider.dart`: `bookingListProvider`, `calendarProvider`, `bookingActionsProvider` + `CalendarParams` với equality
- [x] **P1-3** Tạo `user_provider.dart`: `userListProvider`, `userDetailProvider`, `userActionsProvider`; thêm `UserRepository.getUser(id)`
- [x] **P1-4** Fix `UserFormScreen._loadUser()`: prefill form từ `GET /users/:id`; `_save()` dùng `userActionsProvider`

---

## PHASE 2 — AUTH MODULE

- [x] **P2-1** Redesign `SplashScreen`
  - Lottie animation hoặc flutter_animate branding
  - App logo + tên app
  - Loading indicator đẹp (animated dots thay spinner)
- [x] **P2-2** Redesign `LoginScreen`
  - Hero transition từ splash
  - Card với shadow nhẹ, rounded xl
  - Input fields styled theo M3
  - Loading button animation (text → spinner)
  - Shake animation khi sai mật khẩu
  - Support light/dark mode

---

## PHASE 3 — SHARED COMPONENTS

- [x] **P3-1** Nâng cấp `AppScaffold`
  - Bottom nav: animated selected indicator
  - Theme toggle button (sun/moon icon) trong AppBar
  - User avatar + popup menu cho profile/logout
  - Smooth transition khi switch tab (FadeThrough)
- [x] **P3-2** Nâng cấp `LoadingWidget` — shimmer skeletons
  - `RoomCardSkeleton` (đã có, polish lại)
  - `BookingCardSkeleton`
  - `HomestayCardSkeleton`
  - `UserCardSkeleton`
  - `DetailSkeleton` (cho detail screens)
- [x] **P3-3** Tạo reusable widgets
  - `EmptyStateWidget`: icon animation + message + optional action button
  - `ErrorStateWidget`: icon + message + retry button
  - `AppSnackBar`: helper để show themed snackbars (success/error/info)
- [x] **P3-4** Setup Material Motion transitions
  - `SharedAxisTransition` horizontal/vertical cho GoRouter
  - `FadeScaleTransition` cho modal forms
  - Page transitions trong `GoRouter` (CustomTransitionPage)

---

## PHASE 4 — ROOMS MODULE

- [x] **P4-1** Kết nối `RoomListScreen` với `roomListProvider`
  - Pull-to-refresh → `ref.refresh()`
  - Filter dropdown theo homestay (dùng `homestayListProvider`)
  - Skeleton loading khi chờ data
  - Empty/error states dùng widget reusable
- [x] **P4-2** Redesign `RoomListScreen`
  - `SliverAppBar.large` collapsible header
  - Filter chips horizontal scroll theo homestay
  - Stagger animation items khi load lần đầu (delay 60ms/item)
  - Search bar (client-side filter theo tên phòng)
- [x] **P4-3** Redesign `RoomCard` widget
  - Image ratio 16:9 với price badge overlay (góc phải trên)
  - Status chip (active/inactive)
  - Info row: guests icon + bedrooms icon
  - Scale 0.95 micro-animation khi tap
  - Hero tag trên image cho transition
- [x] **P4-4** Redesign `RoomDetailScreen`
  - Hero animation từ card image → detail header
  - SliverAppBar với ảnh cover full-width collapsible
  - Price cards 4 loại ngày (màu khác nhau, icon)
  - Share deep link
  - Bottom bar thay vì inline buttons
- [x] **P4-5** Redesign `RoomCalendarScreen`
  - Calendar header: tháng/năm navigation đẹp hơn
  - Day cells: màu theo status (HOLD=cam, CONFIRMED=xanh)
  - Tap ngày → bottom sheet với booking details
  - Legend row rõ ràng
- [x] **P4-6** Polish `RoomImagesScreen`
  - Grid fade-in animation khi load
  - Upload progress bar
  - Cover badge animation (star)
  - Delete với long-press + confirm dialog
- [x] **P4-7** Polish `RoomPriceScreen`
  - 4 price cards (màu: xanh/tím/cam/đỏ) thay vì plain inputs
  - Format số tự động (1.000.000đ)
  - Animation khi save thành công
- [x] **P4-8** Polish `RoomFormScreen`
  - Kết nối với `homestayListProvider` cho dropdown homestay
  - Counter fields animation (+ / -)
  - Validation inline

---

## PHASE 5 — BOOKINGS MODULE

- [x] **P5-1** Kết nối `BookingListScreen` với `bookingListProvider`
  - Filter theo status (All / HOLD / CONFIRMED / CANCELLED)
  - Skeleton loading
  - Empty/error states
  - Pull-to-refresh
- [x] **P5-2** Redesign `BookingListScreen`
  - Status color bar bên trái card
  - Countdown timer cho HOLD bookings
  - Status filter chips
  - Confirm/cancel buttons
  - Stagger animation items
- [x] **P5-3** Redesign `HoldRoomScreen`
  - Room info card ở top
  - Night count + estimated price tự động
  - Form fields animated
  - Loading state + AppSnackBar

---

## PHASE 6 — HOMESTAYS MODULE

- [x] **P6-1** Kết nối `HomestayListScreen` với `homestayListProvider`
  - Skeleton loading
  - Empty/error states
  - Pull-to-refresh
- [x] **P6-2** Redesign `HomestayListScreen`
  - Card: map pin icon + địa chỉ, room count badge
  - Owner chip (chỉ ADMIN thấy)
  - Stagger animation
  - Tap card → filter rooms theo homestay
- [x] **P6-3** Polish `HomestayFormScreen`
  - Dùng `homestayActionsProvider` cho create/update
  - Validate lat/lng là số hợp lệ
  - Validate mapLink là URL hợp lệ

---

## PHASE 7 — ADMIN MODULE

- [x] **P7-1** Kết nối `UserListScreen` với `userListProvider`
  - Filter theo role (All / ADMIN / OWNER / SALE)
  - Skeleton loading
  - Pull-to-refresh
- [x] **P7-2** Redesign `UserListScreen`
  - Role badge màu riêng: ADMIN=đỏ, OWNER=tím, SALE=xanh
  - Active/inactive indicator rõ ràng
  - Filter role chips
  - Stagger animation
- [x] **P7-3** Polish `UserFormScreen`
  - `_loadUser()` gọi `GET /users/:id` khi edit mode
  - Role chip animation khi select
  - isActive toggle chỉ hiện khi edit mode
  - AppSnackBar thay thế plain SnackBar

---

## PHASE 8 — POLISH & QUALITY

- [x] **P8-1** Page transitions trong `GoRouter`
  - SharedAxisTransition horizontal cho main list screens
  - SharedAxisTransition vertical cho detail screens
  - FadeScaleTransition cho form screens
- [x] **P8-2** Hero animations
  - Room card image → Room detail header image
  - Hero tag: `'room-cover-${room.id}'`
- [x] **P8-3** Global `AppSnackBar` / Toast system
  - Success: xanh lá + check icon
  - Error: đỏ + x icon
  - Info: xanh dương + info icon
  - Animated slide in/out từ bottom
- [x] **P8-4** Kiểm tra toàn bộ API integration
  - Test login với Admin/Abcd@1234
  - Test CRUD rooms, bookings, homestays, users
  - Test token refresh flow
  - Verify response parsing (đặc biệt `_count` fields)
- [x] **P8-5** Code quality
  - Chạy `flutter analyze` — fix tất cả warnings
  - Chạy `dart format .`
  - Chạy `dart run build_runner build` cho generated files
  - Review và xóa `TODO` comments còn lại

---

## TRACKING

| Phase | Tổng tasks | Đã xong | % |
|-------|-----------|---------|---|
| P0 — Setup & Infrastructure | 7 | 7 | 100% |
| P1 — State Management | 4 | 4 | 100% |
| P2 — Auth Module | 2 | 2 | 100% |
| P3 — Shared Components | 4 | 4 | 100% |
| P4 — Rooms Module | 8 | 8 | 100% |
| P5 — Bookings Module | 3 | 3 | 100% |
| P6 — Homestays Module | 3 | 3 | 100% |
| P7 — Admin Module | 3 | 3 | 100% |
| P8 — Polish & Quality | 5 | 5 | 100% |
| **TỔNG** | **39** | **39** | **100%** |
