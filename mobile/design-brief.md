# Halong24h — Design Brief

> Copy toàn bộ file này paste sang claude.ai web khi cần thiết kế thêm screens mới.
> Claude.ai sẽ dùng làm context để tạo design nhất quán với app hiện tại.

---

## 1. App Overview

- **Tên app**: Halong24h — app đặt & quản lý phòng homestay vùng Hạ Long
- **Bundle ID**: `com.halongtravel.halong24h`
- **Platform**: Flutter (iOS + Android), Material Design 3
- **Ngôn ngữ UI**: Tiếng Việt
- **Font**: Google Fonts **Nunito** (toàn bộ app)
- **Roles người dùng**: ADMIN, OWNER (Chủ nhà), SALE, CUSTOMER (Khách hàng)
- **Hai chế độ UI**: Owner/Sale/Admin (manager view) ↔ Customer (booking view) — chuyển qua `viewModeProvider`
- **Mood / Cảm xúc thiết kế**: Biển — sang trọng, mát mẻ, tin cậy. Ocean blue + gold accent gợi cảm giác Hạ Long bay & dịch vụ cao cấp.

---

## 2. Design System

### 2.1 Color Palette

```
PRIMARY — Ocean blue (Hạ Long bay)
- ocean       #0A4F6E   (main brand — primary)
- oceanMid    #0D6E96   (primaryLight)
- oceanDeep   #062D42   (primaryDark)
- oceanLight  #E8F4FA   (subtle bg)
- oceanPale   #F0F8FC   (subtle bg lighter)

SECONDARY — Premium gold
- gold        #C9A84C   (secondary, premium accent)
- goldLight   #FDF6E3

ACCENT — Teal
- teal        #00B4D8
- tealLight   #CAF0F8

NEUTRAL (Slate scale)
- navy        #0F172A
- ink         #1E293B
- muted       #64748B
- slate       #94A3B8
- slateLight  #F1F5F9
- border      #E2E8F0
- divider     #E2E8F0
- background     #F8FAFC   (light scaffold)
- surface        #FFFFFF
- backgroundDark #0F172A
- surfaceDark    #1E293B

SEMANTIC
- emerald (success) #22C55E   bg: #DCFCE7
- amber   (warning) #F59E0B   bg: #FEF3C7
- coral   (error)   #EF4444   bg: #FEE2E2
- info               oceanMid

BOOKING / ROOM STATUS
- hold        #F59E0B  (cam — đang giữ)
- confirmed   #22C55E  (xanh lá — đã xác nhận)
- cancelled   #EF4444  (đỏ — đã huỷ)
- completed   #7B1FA2  (tím — đã hoàn tất)
- vacant      emerald   (còn trống)
- booked      amber     (đã đặt)
- occupied    oceanMid  (đang ở)
- maintenance slate     (bảo trì)

DARK THEME — Soft slate (không nặng)
- darkBackground  #1A2232   (scaffold bg)
- darkSurface     #212C3F   (card)
- darkContainer   #283448   (input/elevated)
- darkElevated    #2F3E54   (modal/dialog/sheet)
- darkBorder      #364D65
- darkDivider     #2A3A4F
- darkHint        #8FA8BC
- darkSubtext     #7090AA
- darkTextPrimary #E6F0F8
- oceanBright     #48C9F0   (primary accent on dark)
- tealBright      #26D9C8
- goldBright      #D4AE5C

ACCENT SEMANTIC
- brownDark      #92400E
- greenDark      #065F46
- greenForest    #166534
- purple         #7B1FA2
- blueWeekday    #1976D2
- orangeHoliday  #E65100
```

### 2.2 Typography (Nunito)

| Style          | Size | Weight |
|----------------|------|--------|
| displayLarge   | 57   | w400   |
| displayMedium  | 45   | w400   |
| displaySmall   | 36   | w400   |
| headlineLarge  | 32   | w700   |
| headlineMedium | 28   | w600   |
| headlineSmall  | 24   | w600   |
| titleLarge     | 22   | w600   |
| titleMedium    | 16   | w600   |
| titleSmall     | 14   | w600   |
| bodyLarge      | 16   | w400   |
| bodyMedium     | 14   | w400   |
| bodySmall      | 12   | w400   |
| labelLarge     | 14   | w600   |
| labelMedium    | 12   | w500   |
| labelSmall     | 11   | w500   |

> Trong components thực tế, tiêu đề mạnh thường dùng **w700–w800** để tạo visual weight.

### 2.3 Spacing Scale (`AppSpacing`)

```
xs   = 4px
sm   = 8px
md   = 16px   ← default padding
lg   = 24px
xl   = 32px
xxl  = 48px
```

### 2.4 Border Radius (`AppRadius`)

```
xs   = 4px
sm   = 8px
md   = 12px   ← default cho input/button
lg   = 16px   ← default cho card
xl   = 24px   ← cho card lớn / bottom sheet
full = 100px  ← pill shape (chip, badge, status pill)
```

### 2.5 Elevation / Shadow

- **Card mặc định**: elevation 0, có border `border` (#E2E8F0), radius `lg`
- **Card nổi (room/property card)**: shadow `Color.black.alpha(0.06)`, blur 20, offset (0, 6), radius `xl`
- **Bottom Nav**: shadow `Color.black.alpha(0.08)`, blur 20, offset (0, -4), top corners radius 24
- **FAB / Center button**: shadow `primary.alpha(0.35)`, blur 12, offset (0, 4)
- **Greeting header gradient**: `ocean → oceanMid` (light) / `oceanDeep → oceanMid` (dark)

---

## 3. Component Patterns

### 3.1 AppBar
- Background: `surface` (white/dark surface)
- Foreground: `primary` (ocean) color
- Elevation 0 (1 khi scroll)
- Title align left, font Nunito w700 size 20
- **Right actions**: theme toggle icon + notification bell (badge dot nếu unread) + user avatar (CircleAvatar với chữ cái đầu, primary bg)
- User avatar mở popup menu: tên + role pill + view-mode switcher + logout

### 3.2 Bottom Navigation (custom — `AppScaffold`)

Cấu trúc thay đổi theo **viewMode**:

**Manager view** (Owner/Sale/Admin) — 5 tab:
**Dashboard — Calendar — [Center FAB +] — Bookings/Reports — Profile**

**Customer view** — 5 tab:
**Home — Search — [Center FAB] — My Bookings — Account**

- Center FAB: 56x56 circle, gradient `oceanMid → ocean`, icon `+` (manager) hoặc `search` (customer), mở bottom sheet "Tạo nhanh"
- Selected tab: pill background `primary.alpha(0.12)` quanh icon, text w700 primary
- Unselected: icon outline color `outline`, text w500
- Top corners rounded 24, soft shadow trên top
- Bottom sheet manager: Thêm phòng / Đặt phòng giữ chỗ / Thêm khách hàng

### 3.3 Buttons
- **ElevatedButton / FilledButton**: full width (min 52 height), radius `md`, w600
- **OutlinedButton**: same size, border 1.5px primary
- **FAB**: circle, primary bg (ocean), white icon
- **TextButton**: foreground primary, w600

### 3.4 Input Field
- Filled, surface bg, radius `md`, border 1px `border` (#E2E8F0)
- Focus: border 2px primary
- Error: border `coral`
- Padding horizontal `md`, vertical 14
- Hint color `muted`
- VND amount: dùng `VndInputFormatter` (1.000.000)

### 3.5 Cards (general pattern)
- Radius `lg` (16) hoặc `xl` (24) cho card nổi
- Border 1px `border` (light) / `darkBorder` (dark)
- ClipBehavior antiAlias

### 3.6 Room Card / Property Card (signature component)
- Stack: image 16:10 trên đầu, info section dưới
- **Overlays trên image**:
  - Top-left: status pill (success/grey với dot indicator) — "Hoạt động" / "Tạm nghỉ"
  - Top-right: image count badge (black 55% transparent + photo icon + count)
  - Bottom-right: price pill (ocean bg, white text w800) — format VND
  - Bottom: gradient transparent → black 40% từ trên xuống
- **Info section**:
  - Row: tên phòng (w800 size 17) + code chip (primary outline pill)
  - Location row: location_on icon ocean + tên homestay/property
  - Info chips row: people + bedroom + bathroom (icon trong rounded square ocean 8% bg)
  - Amenities row (optional): chip nhỏ wifi/parking/pool…
- **Animation**: tap scale 0.97, list entrance fadeIn + slideY staggered (delay 80ms × index)

### 3.7 Chips
- ChoiceChip / FilterChipTile: radius full (pill), selected = primary bg + white w700, unselected = surface + onSurface w500
- Status chip: pill shape, semantic color bg, white text w700

### 3.8 Calendar Grid (`CalendarGridWidget`)
- 7 cột × 5–6 hàng, mỗi cell radius `sm`
- Cell states:
  - Vacant: `vacantBg` (emerald light) + dot emerald
  - Booked/Hold: `bookedBg` (amber light) + dot amber + tên khách (truncate)
  - Occupied: `occupiedBg` (ocean light) + dot oceanMid
  - Maintenance: `maintenanceBg` (slate light) + slash pattern
  - Selected: border 2px primary
  - Today: ring primary
  - Weekend / Holiday: text accent
- Header tháng có nút trái/phải, tap để mở year picker
- Legend dưới calendar

### 3.9 Date Picker Tile (`DatePickerTile`)
- Tile chứa label + ngày được chọn (format `dd/MM/yyyy`)
- Trailing chevron, leading icon calendar primary
- Tap mở showDatePicker với theme primary
- Range mode: 2 tile cạnh nhau (Check-in → Check-out) + đếm số đêm

### 3.10 Guest Counter (`GuestCounter`)
- Row: label trái + nhóm `[ - ] count [ + ]` phải
- Button minus/plus circle 32x32, primary 12% bg, disabled khi reach limit
- Dùng cho: số người lớn / trẻ em / phòng

### 3.11 Section Label (`SectionLabel`)
- Title w700 size 16 ink + subtitle (optional) muted size 12
- Optional trailing action TextButton "Xem tất cả →" primary

### 3.12 Empty State
- Center icon trong circle 96x96 với primary 8% bg
- Text title w700 size 16
- Subtext color onSurface 50%
- Optional FilledButton.tonal action
- Animation: scale elastic + fadeIn cascade

### 3.13 Error State
- Same layout as empty state
- Icon `cloud_off_rounded` trong circle error 8% bg
- Title "Có lỗi xảy ra" + error message
- Retry button: FilledButton.icon với refresh icon, error color bg

### 3.14 Loading / Skeleton
- Shimmer effect cho card placeholders
- Skeleton variations: RoomCardSkeleton, BookingCardSkeleton, PropertyCardSkeleton, UserCardSkeleton, DetailSkeleton, CalendarSkeleton
- SkeletonList: staggered fadeIn 60ms × index

### 3.15 SnackBar (`AppSnackBar`)
- Floating behavior, radius `md`, margin `md`
- Có icon + text trắng w600
- Variants: success (emerald), error (coral), info (ocean)

### 3.16 Greeting Header (Home / Dashboard)
- Gradient `ocean → oceanMid` từ top-left → bottom-right
- Bottom corners rounded 28
- Greeting text trắng 80% alpha + tên user trắng w800 size 22
- Notification bell icon trong rounded square với white 20% alpha bg, dot badge khi có unread
- Search bar nổi bên dưới (optional): surface bg, radius full, soft shadow, search icon ocean, suffix tune icon

### 3.17 Category Icons / Quick Actions
- Circle 60x60, color 10% alpha bg (selected: full color + shadow)
- Icon size 28, color hoặc white khi selected
- Label dưới size 12 w600

### 3.18 Splash Screen
- Background: gradient `ocean → oceanMid`
- Logo `logohalong24h.png` center + tên "Halong24h" w800 white
- Loading dot animation hoặc CircularProgressIndicator white
- Native splash screen Android 12+ dùng `splash_android12.png`

---

## 4. Screens hiện có (đã build)

### Auth
- **Splash screen** — logo + ocean gradient + redirect logic
- **Login screen** — phone/email + password + nút Google login (placeholder)
- **Register screen** — đăng ký khách hàng
- **Forgot password screen** — gửi OTP + reset

### Customer flow (role CUSTOMER)
- **Customer Home** — greeting + search bar + featured rooms + nearby properties
- **Search Room** — filter (date range, guest count, price, amenities)
- **My Bookings** — list booking đã đặt + status filter
- **Account** — info tóm tắt + menu (profile, payments, support, logout)

### Manager flow (OWNER / SALE / ADMIN)
- **Dashboard** — stats cards (revenue, occupancy, pending bookings) + recent activity + charts
- **Reports** — biểu đồ doanh thu / occupancy / customer / theo tháng

### Rooms
- **Room List** — greeting header, search bar, category icons, filter chips, list room cards
- **Room Detail** — hero image carousel, info, amenities, calendar, actions (edit/hold/disable)

### Bookings
- **Booking List** — list + status filter chips + search
- **Booking Calendar** — calendar view của 1 phòng
- **Owner Calendar** — calendar tổng các phòng của owner (multi-room timeline)
- **Hold Room** — form tạo booking giữ phòng (chọn ngày, khách, tiền cọc)

### Properties (thay thế Homestays cũ)
- **Property Management** — list properties (homestay/villa) của owner
- **Property Manage** — chi tiết quản lý 1 property (rooms, bookings, stats)
- **Property Add** — wizard tạo mới (info → location → images → amenities → services → rules → pricing → cancellation)
- **Property Info / Location / Images / Amenities / Services / Rules / Pricing / Cancellation** — các step riêng

### Calendar (top-level)
- **Calendar screen** — calendar view chính (manager xem tất cả)

### Notifications
- **Notification screen** — list thông báo + mark as read

### Profile
- **Profile screen** — info user + role + menu
- **Personal Info** — edit thông tin cá nhân
- **Change Password**
- **Help / Support** — FAQ + contact

### Admin
- **Admin Screen** — dashboard tổng cho admin
- **User List** — quản lý nhân viên
- **User Form** — create/edit user

---

## 5. Navigation Structure

```
/splash
/login    /register    /forgot-password

# Customer view (viewMode = customer)
/home                       (Bottom nav 0)
/search                     (Bottom nav 1)
/my-bookings                (Bottom nav 3)
/account                    (Bottom nav 4)

# Manager view (Owner/Sale/Admin)
/dashboard                  (Bottom nav 0)
/calendar                   (Bottom nav 1)
/bookings                   (Bottom nav 3)
/reports
/rooms
  /rooms/:id
    /rooms/:id/hold
/properties
  /properties/new
  /properties/:id
    /properties/:id/info
    /properties/:id/images
    /properties/:id/amenities
    /properties/:id/pricing
    /properties/:id/services
    /properties/:id/rules
    /properties/:id/location
    /properties/:id/cancellation

# Admin only
/admin
/admin/rooms
/admin/owner-calendar
/admin/users
  /admin/users/new
  /admin/users/:id/edit

# Shared
/notifications
/profile
  /profile/edit
  /profile/change-password
  /profile/help
```

Page transitions: horizontal slide cho main, slide-up cho detail/sub, fade+scale cho forms.

---

## 6. Animation Patterns

- Library: `flutter_animate`
- **Entry animations**: fadeIn 300–400ms + slideY (begin 0.08–0.2)
- **Stagger**: delay = index × 60–80ms
- **Empty/Error icon**: scale elastic begin (0.7, 0.7) + fadeIn
- **Tap feedback**: AnimatedScale 0.97 trong 120ms easeOut
- **Theme toggle**: AnimatedSwitcher rotation + fade 300ms
- **View mode switch**: AnimatedSwitcher slideX + fade 300ms
- **Bottom nav selected**: AnimatedContainer 300ms easeOutCubic cho pill bg
- **FAB elastic on mount**: scale begin (0.8, 0.8) elasticOut 400ms delay 200ms
- **Calendar cell tap**: scale 0.95 + ripple

---

## 7. Tone & Content Style (Vietnamese)

- Greeting: "Chào buổi sáng/chiều/tối, {name}"
- CTAs (manager): "Thêm phòng", "Đặt phòng", "Tạo property", "Xem tất cả", "Tạo nhanh"
- CTAs (customer): "Đặt ngay", "Tìm phòng", "Xem chi tiết", "Liên hệ"
- Empty: "Chưa có phòng nào", "Chưa có booking", "Nhấn + để thêm mới"
- Error: "Có lỗi xảy ra", "Thử lại", "Không thể kết nối"
- Status labels: "Hoạt động" / "Tạm nghỉ" / "Đã xác nhận" / "Đã huỷ" / "Đã hoàn tất" / "Đang giữ" / "Còn trống" / "Đã đặt"
- Roles: "Quản trị" / "Chủ nhà" / "Sale" / "Khách hàng"
- Format tiền: `1.000.000đ` (dấu chấm nghìn, đ cuối)
- Format ngày: `dd/MM/yyyy` (vd: 27/04/2026)

---

## 8. Yêu cầu khi thiết kế screen mới

Khi thiết kế screen mới, vui lòng:
1. Dùng đúng **ocean blue + gold** palette + Nunito font
2. Theo spacing/radius scale (`AppSpacing` / `AppRadius`)
3. Wrap trong `AppScaffold` (có bottom nav theo viewMode + appbar pattern sẵn)
4. Áp dụng Material 3 — không trộn iOS-style cho Android
5. Đối với iOS, có thể dùng Cupertino touches nhẹ (haptic, swipe back) nhưng giữ đồng nhất visual với Android
6. Empty/Error/Loading states có sẵn pattern — mô tả ngữ cảnh dùng
7. Mọi text bằng tiếng Việt
8. Animation theo pattern mục 6
9. Support cả light + dark theme (slate dark, không pure black)
10. Phân biệt rõ **manager view** vs **customer view** — chỉ rõ screen dành cho role nào
11. Mô tả rõ data/state nguồn nào (controller/provider) và actions nào trigger gì

---

## 9. Tech Stack tham khảo (cho dev biết)

- Flutter 3.x + Material 3
- State: `flutter_riverpod` 2.6+ với code gen (`@riverpod`)
- Routing: `go_router` 14
- HTTP: `dio` 5
- Animation: `flutter_animate`, `shimmer`
- Image: `cached_network_image`
- Font: `google_fonts` (Nunito)
- Date: `intl` (DateFormat)
- Native splash: `flutter_native_splash` (logohalong24h, splash, splash_android12)

### Cấu trúc thư mục (chuẩn project)

```
lib/
  core/
    constants/   network/   storage/   theme/   utils/
  data/
    models/   repositories/
  features/
    admin/        auth/         bookings/    calendar/
    customer/     dashboard/    notifications/
    profile/      properties/   reports/     rooms/
      <feature>/
        controllers/   ← Riverpod providers/notifiers
        views/         ← Screen files
        widgets/       ← Feature-scoped widgets
  shared/
    providers/   ← authProvider, viewModeProvider, partnerRepositoryProvider, routerProvider
    widgets/     ← AppScaffold, LoadingWidget, CalendarGridWidget, DatePickerTile,
                   FilterChipTile, GuestCounter, SectionLabel
  main.dart
```

> Quy ước: `controllers/` thay cho `providers/` cũ, `views/` thay cho `screens/` cũ. Khi đề xuất file mới, đặt theo cấu trúc này.
