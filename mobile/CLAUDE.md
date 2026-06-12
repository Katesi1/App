# CLAUDE.md — Project Operating System

Tài liệu này là **hệ điều hành dự án** — định nghĩa conventions, execution flow, và quality gates để AI (Claude Code) và dev luôn code nhất quán, đúng trình tự.

---

## 1. PROJECT CONTEXT

- **App**: Homestay Management Mobile App (Halong24h)
- **Mục tiêu**: Quản lý homestay, phòng, booking cho chủ homestay + đặt phòng cho khách hàng
- **Architecture**: MVC (Model - View - Controller) với Riverpod
- **Platform**: Flutter (iOS + Android)
- **Language**: Dart 3.5+
- **Backend API**: `http://160.30.169.42:3000`
- **Swagger docs**: `http://160.30.169.42/index.html`

### Phạm vi

- ✅ **Được làm**: CRUD rooms/bookings/homestays/users, auth (phone + Google),
  customer booking flow, dashboard KPI, role-based UI, KYC + subscription
  flow cho OWNER (xem Section 14), admin KYC queue, staff (SALE) scope theo
  `ownerId`
- ❌ **KHÔNG được làm**: Tự ý thêm dependency chưa hỏi, thay đổi architecture
  (MVC → MVVM, BLoC...), bỏ Riverpod sang provider khác, hardcode config/secret,
  xoá mock repository (giữ song song với real impl cho QA)

### Tech Stack

| Thành phần | Package |
|---|---|
| UI Framework | Flutter SDK + Material Design 3 |
| State Management | `flutter_riverpod ^2.6.1` |
| Navigation | `go_router ^14` |
| HTTP Client | `dio ^5` |
| Auth | `google_sign_in ^6.2` |
| Secure Storage | `flutter_secure_storage` |
| Local Prefs | `shared_preferences` |
| JSON | `json_annotation` + `json_serializable` |
| Equality | `equatable` |
| UI | `cached_network_image`, `image_picker`, `photo_view`, `table_calendar`, `shimmer` |
| Animation | `flutter_animate`, `animations`, `lottie` |
| Typography | `google_fonts` (BeVietnamPro) |
| Linting | `flutter_lints` + `riverpod_lint` + `custom_lint` |

---

## 2. CODING RULES

### Dart / Flutter Convention

- **Naming**: `UpperCamelCase` cho class/type, `lowerCamelCase` cho biến/hàm, `lowercase_with_underscores` cho file
- **Files**: Mỗi file một class/widget chính; tên file = tên class (snake_case)
- **Imports**: Relative imports; nhóm theo: dart → flutter → packages → local
- **Formatting**: `dart format`; line limit 80 ký tự
- **Control flow**: Luôn dùng curly braces `{}`
- **Variables**: Ưu tiên `final` > `var`; dùng `const` khi có thể
- **Types**: Annotate return type và parameter khi type không hiển nhiên
- **Async/await** thay vì `.then()` chains

### Dart 3 Features (ưu tiên dùng)

- **Records** cho multiple return values
- **Patterns** cho destructure
- **Switch expressions** cho control flow ngắn gọn
- **Sealed classes** + `switch` cho exhaustiveness
- **if-case** + `when` guard clause

### Folder Structure (MVC)

```
lib/
  core/                          # Framework & infrastructure
    constants/
      api_constants.dart         # Base URL + tất cả API endpoints
      app_constants.dart         # Enums (UserRole, BookingStatus), app config
    network/
      api_client.dart            # Dio singleton + AuthInterceptor (auto token, auto refresh 401)
      api_response.dart          # ApiResponse<T> generic wrapper + parseDioError()
    storage/
      secure_storage.dart        # FlutterSecureStorage wrapper (token, user data)
    theme/
      app_colors.dart            # ← TẤT CẢ màu dùng chung (KHÔNG hardcode Color() ở nơi khác)
      app_spacing.dart           # AppSpacing (xs..xxl) + AppRadius (xs..full)
      app_theme.dart             # Light + Dark theme (Material 3)
    utils/
      app_router.dart            # GoRouter + auth redirect logic
      app_transitions.dart       # Custom page transitions
      helpers.dart               # ← AppHelpers: roleLabel, roleColor, formatPrice, vietnameseDayOfWeek...

  data/                          # MODEL layer
    models/
      user_model.dart            # UserModel (role: isAdmin/isOwner/isSale/isCustomer, KYC: isKycApproved/needsKyc, subscription: isInTrial/trialDaysLeft)
      room_model.dart            # RoomModel, RoomImageModel, RoomPriceModel, HomestaySimpleModel
      homestay_model.dart        # HomestayModel
      booking_model.dart         # BookingModel, CalendarBooking
      notification_model.dart    # NotificationModel + NotificationType (booking|payment|system) + targetType discriminator
    repositories/
      auth_repository.dart       # Login, register, Google sign-in, logout, token management
      user_repository.dart       # CRUD users
      room_repository.dart       # CRUD rooms, images, prices
      homestay_repository.dart   # CRUD homestays
      booking_repository.dart    # CRUD bookings, calendar, hold/confirm/cancel (staff)
      customer_repository.dart   # Public rooms, customer-hold, my-bookings, customer-cancel

  features/                      # Feature modules (MVC per feature)
    auth/
      controllers/
        auth_controller.dart     # AuthNotifier, authProvider, currentUserProvider, isCustomerModeProvider
      views/
        login_screen.dart        # Login form + Google Sign-In
        register_screen.dart     # Đăng ký (chọn role STAFF/CUSTOMER + form)
        splash_screen.dart       # Splash animation + auto-redirect
    customer/
      controllers/
        customer_controller.dart # publicRoomsProvider, myBookingsProvider, customerBookingProvider
      views/
        customer_home_screen.dart  # Trang chủ khách (welcome, quick actions, phòng nổi bật)
        search_room_screen.dart    # Tìm phòng (filter ngày, khách, giá)
        my_bookings_screen.dart    # Booking của tôi (tabs: tất cả/hold/confirmed/cancelled)
        account_screen.dart        # Tài khoản (profile, toggle quản lý, dark mode, logout)
    dashboard/
      views/
        dashboard_screen.dart    # KPI cards, status pills, quick actions, today's bookings
    rooms/
      controllers/
        room_controller.dart     # roomListProvider, roomDetailProvider
      views/
        room_list_screen.dart
        room_detail_screen.dart
        room_form_screen.dart
        room_calendar_screen.dart
        room_images_screen.dart
        room_price_screen.dart
      widgets/
        room_card.dart
    bookings/
      controllers/
        booking_controller.dart  # bookingListProvider, calendarProvider, BookingActionsNotifier
      views/
        booking_list_screen.dart
        hold_room_screen.dart
    homestays/
      controllers/
        homestay_controller.dart # homestayListProvider, HomestayActionsNotifier
      views/
        homestay_list_screen.dart
        homestay_form_screen.dart
    admin/
      controllers/
        user_controller.dart     # userListProvider, UserActionsNotifier
        kyc_approval_controller.dart  # kycQueueProvider, KYCApprovalActionsNotifier (approve/reject)
      data/
        models/
          kyc_submission.dart    # KYCSubmission view-model cho admin queue
        repositories/
          admin_kyc_repository.dart        # Abstract + provider
          admin_kyc_repository_impl.dart   # Real backend (gọi /admin/kyc/queue, /admin/kyc/submissions/:id/approve|reject)
          mock_admin_kyc_repository.dart   # Seed 5 submission cho QA
      views/
        admin_screen.dart
        user_list_screen.dart
        user_form_screen.dart
        kyc_approval_list_screen.dart    # 4-tab queue (chờ duyệt / đã duyệt / bị từ chối / tất cả)
        kyc_approval_detail_screen.dart  # CCCD images + OCR + face match + approve/reject
    verify/                       # KYC flow cho OWNER (xem Section 14)
      controllers/
        verify_flow_controller.dart   # VerifyFlowController + verifyRepositoryProvider + verifyPlansProvider
      data/
        models/                       # cccd_upload, selfie_upload, ocr_result, plan, payment_session, verify_state, verify_enums
        repositories/
          verify_repository.dart        # Abstract + KycStatusSnapshot
          verify_repository_impl.dart   # Real backend (FPT.AI/VNPay sau, hiện wire trực tiếp /kyc/*, /payments/*, /billing/plans)
          mock_verify_repository.dart   # Mock cho QA — override provider
      views/                        # 7 screen: cccd_capture/scanner, selfie_capture/scanner, select_plan, payment, pending_approval, trial_active, rejected
        widgets/                    # camera_frame_overlay, status_timeline, plan_card, order_summary_card...
      utils/
        cccd_image_cropper.dart     # Crop CCCD ratio 1.586:1
        camera_picker.dart
    notifications/
      controllers/
        notification_controller.dart  # notificationListProvider, unreadCountProvider, mark-as-read
      views/
        notification_screen.dart

  shared/                        # Code dùng chung giữa các features
    providers/
      theme_provider.dart        # ThemeNotifier (light/dark, persist SharedPreferences)
      view_mode_provider.dart    # ViewModeNotifier (management/customer, persist SharedPreferences)
    widgets/
      app_scaffold.dart          # AppScaffold (AppBar + BottomNav dynamic theo role/viewMode + toggle + user menu)
      loading_widget.dart        # LoadingWidget, Skeletons, EmptyStateWidget, ErrorStateWidget, AppSnackBar

  main.dart                      # ProviderScope → MaterialApp.router
```

### Quy tắc thư mục

- **MVC per feature**: Mỗi feature có `controllers/` (state + logic), `views/` (UI screens), `widgets/` (reusable UI components)
- **Không import chéo giữa features** — dùng `shared/` hoặc `core/` cho code dùng chung
- **Controllers** đặt trong `features/<feature>/controllers/`
- **Data flow**: unidirectional — UI → event → Controller → Repository → API → Controller → UI rebuild

---

## 3. SKILLS AVAILABLE

Các skill template giúp dev/AI thực hiện đúng quy trình cho từng loại task.

| Skill | File | Mô tả |
|-------|------|-------|
| **scaffolding** | `skills/scaffolding/SKILL.md` | Tạo cấu trúc module/feature mới đúng MVC pattern |
| **verification** | `skills/verification/SKILL.md` | Kiểm tra code trước khi báo done (4C checklist) |
| **review** | `skills/review/SKILL.md` | Phản biện logic, quality, performance |

### Khi nào dùng skill nào

| Bạn đang làm gì? | Dùng skill |
|-------------------|------------|
| Tạo feature mới / thêm module | `scaffolding` → `verification` |
| Sửa bug / thêm logic | `verification` |
| Review PR / check chất lượng | `review` |
| Refactor code | `review` → `verification` |

---

## 4. EXECUTION FLOW (mọi task đều theo)

```
SCOPE → SKILL → EXECUTE → VERIFY → EVOLVE
```

### Step 1: SCOPE — Xác định rõ yêu cầu

- Task cần làm gì? Output mong muốn là gì?
- Ảnh hưởng đến file/module nào?
- Có cần tạo mới hay sửa existing?
- Check `lessons/gotchas.md` xem có edge case đã gặp không

### Step 2: SKILL — Chọn skill phù hợp

- Đọc skill tương ứng trong `skills/<skill>/SKILL.md`
- Follow template và checklist trong skill
- Nếu task phức tạp, kết hợp nhiều skill (VD: scaffolding → verification)

### Step 3: EXECUTE — Viết code theo convention

- Follow coding rules ở Section 2
- Dùng đúng patterns (xem Section dưới: Models, Repositories, Controllers, Views)
- Check `AppColors`, `AppHelpers`, `shared/widgets/` trước khi viết mới
- **KHÔNG duplicate code** — check existing trước

### Step 4: VERIFY — Chạy verification checklist

Bắt buộc chạy trước khi báo done. Xem chi tiết Section 5.

```bash
# Analyze
flutter analyze

# Format
dart format .

# Test
flutter test

# Code gen (nếu thêm/sửa model)
dart run build_runner build --delete-conflicting-outputs
```

### Step 5: EVOLVE — Ghi lại bài học

- Gặp edge case mới? → Ghi vào `lessons/gotchas.md`
- Pattern mới hữu ích? → Cập nhật skill liên quan
- Bug do convention thiếu? → Cập nhật CLAUDE.md

---

## 5. VERIFICATION CHECKLIST (bắt buộc trước khi done)

### Correctness — Logic đúng

- [ ] Logic đúng với yêu cầu không?
- [ ] Không có bug hiển nhiên?
- [ ] Edge case đã xử lý? (null, empty list, error state, offline)
- [ ] API response format đúng? (`response.data['data']`)

### Completeness — Đủ file, đủ layer

- [ ] Đủ các file cần thiết? (model → repository → controller → view)
- [ ] Có error handling không? (`ApiResponse.error()`, `ErrorStateWidget`)
- [ ] Có loading state không? (`LoadingWidget`, `SkeletonList`)
- [ ] Có empty state không? (`EmptyStateWidget`)
- [ ] Unit test cho logic mới?

### Context-fit — Đúng convention dự án

- [ ] Đúng tech stack? (Riverpod, GoRouter, Dio)
- [ ] Theo đúng folder structure MVC?
- [ ] Dùng `AppColors` thay vì hardcode `Color()`?
- [ ] Dùng `AppHelpers` thay vì duplicate logic?
- [ ] Dùng `shared/widgets/` cho widget dùng chung?
- [ ] Không import chéo giữa features?
- [ ] `const` ở mọi nơi có thể?

### Consequence — Rủi ro khi deploy

- [ ] Nếu deploy thật, rủi ro lớn nhất là gì?
- [ ] Có ảnh hưởng đến flow hiện tại không?
- [ ] Route guard có chặn đúng role không?
- [ ] Token/auth có bị ảnh hưởng không?

---

## 6. SKILL TEMPLATES

### Khi tạo feature/module mới

1. Đọc `skills/scaffolding/SKILL.md`
2. Tạo folder structure: `features/<name>/controllers/`, `views/`, `widgets/`
3. Tạo theo thứ tự: **Model → Repository → Controller → View → Route**
4. Chạy verification checklist (Section 5)

### Khi review code

1. Đọc `skills/review/SKILL.md`
2. Kiểm tra **4C**: Correctness, Completeness, Context-fit, Consequence
3. Check performance rules (Section 10)
4. Check anti-patterns (Section 7)

### Khi có lỗi/edge case mới

1. Ghi vào `lessons/gotchas.md` với format: **Vấn đề → Nguyên nhân → Giải pháp**
2. Cập nhật skill liên quan nếu cần
3. Thêm test case reproduce bug

---

## 7. ANTI-PATTERNS (không được làm)

### Code Quality

| # | Anti-pattern | Phải làm |
|---|-------------|---------|
| 1 | Hardcode `Color(0xFF...)` | Dùng `AppColors.*` |
| 2 | Duplicate logic (copy-paste helper) | Dùng `AppHelpers` |
| 3 | Hardcode Base URL | Dùng `ApiConstants.baseUrl` |
| 4 | `setState` trong `ConsumerWidget` | Dùng Riverpod state |
| 5 | Throw exception từ Repository | Dùng `ApiResponse.error()` |
| 6 | Import chéo giữa features | Dùng `shared/` hoặc `core/` |
| 7 | Tự tạo `Dio()` instance | Dùng `ApiClient.instance` |
| 8 | Private widget dùng chung trong view | Tách ra `shared/widgets/` |
| 9 | `ref.read(derivedProvider)` trong GoRouter redirect | Tính trực tiếp từ `authState.user` + `ref.read(viewModeProvider)` |
| 10 | Tạo `Repository()` trực tiếp | Dùng provider |
| 11 | Function > 50 lines không lý do | Tách nhỏ |
| 12 | Hardcode config/secret | Dùng constants/env |
| 13 | Bỏ qua error handling | Luôn handle error state |
| 14 | Tạo file mới khi chưa check existing | Kiểm tra `shared/`, `core/` trước |
| 15 | Không `const` khi có thể | Luôn `const` widget, constructor, giá trị cố định |

### Performance

| # | Anti-pattern | Severity |
|---|-------------|----------|
| 1 | `CachedNetworkImage` không có `memCacheWidth` | **HIGH** |
| 2 | `Column` + `map` thay vì `ListView.builder` | **HIGH** |
| 3 | `invalidate()` không truyền param cho `.family` | **HIGH** |
| 4 | TabBarView + ListView không có `AutomaticKeepAliveClientMixin` | **HIGH** |
| 5 | Search input không debounce | **MEDIUM** |
| 6 | Animation > 2 effects per item, stagger > 5 items | **MEDIUM** |
| 7 | Không dispose controllers trong `dispose()` | **MEDIUM** |
| 8 | `ref.watch` trong callback / `ref.read` trong `build()` | **MEDIUM** |
| 9 | `invalidate()` trong `build()` (infinite loop) | **HIGH** |
| 10 | Không check `mounted` trước setState trong async | **LOW** |

---

## 8. LESSONS LEARNED

→ Xem `lessons/gotchas.md` cho danh sách edge cases và bài học từ quá trình phát triển.

---

## 9. DESIGN SYSTEM — Halong24h

### Brand Colors

| Tên | Hex | AppColors |
|---|---|---|
| Ocean Deep | `#062D42` | `AppColors.oceanDeep` |
| Ocean Primary | `#0A4F6E` | `AppColors.ocean` |
| Ocean Mid | `#0D6E96` | `AppColors.oceanMid` |
| Teal Accent | `#00B4D8` | `AppColors.teal` |
| Gold Premium | `#C9A84C` | `AppColors.gold` |

### Status Badges

| Trạng thái | Hex | Mô tả | AppColors |
|---|---|---|---|
| Trống | `#22C55E` | Phòng sẵn sàng | `AppColors.emerald` |
| Đã đặt | `#F59E0B` | Có booking tới | `AppColors.amber` |
| Đang ở | `#0D6E96` | Khách đang ở | `AppColors.oceanMid` |
| Bảo trì | `#94A3B8` | Đang bảo trì | `AppColors.slate` |
| Đã huỷ | `#EF4444` | Booking huỷ | `AppColors.coral` |
| Xác nhận | `#22C55E` | Booking OK | `AppColors.emerald` |

### Typography (Be Vietnam Pro)

| Style | Size | Weight | Dùng cho |
|---|---|---|---|
| H1 | 24px | Bold 700 | Tiêu đề lớn |
| H2 | 18px | Bold 700 | Tiêu đề |
| H3 | 15px | SemiBold 600 | Heading card |
| Body | 14px | Regular 400 | Text thông thường |
| Caption | 12px | Regular 400 | Label phụ |
| Section Label | 11px | SemiBold 600 + Uppercase | Nhãn section |

### Colors — AppColors (QUAN TRỌNG)

**KHÔNG BAO GIỜ hardcode `Color(0xFF...)` trong code.** Tất cả màu phải khai báo trong `lib/core/theme/app_colors.dart`.

```dart
// ✅ ĐÚNG
color: AppColors.ocean
color: AppColors.brownDark

// ❌ SAI — hardcode color
color: Color(0xFF92400E)
color: const Color(0xFF1976D2)
```

#### Danh sách màu có sẵn

| Nhóm | Tên | Mô tả |
|---|---|---|
| **Primary** | `ocean`, `oceanMid`, `oceanDeep`, `oceanLight`, `oceanPale` | Ocean blue (Hạ Long bay) |
| **Accent** | `teal`, `tealLight`, `gold`, `goldLight` | Teal + Gold premium |
| **Neutral** | `navy`, `ink`, `muted`, `slate`, `slateLight`, `border`, `background`, `surface` | Text + background |
| **Semantic** | `emerald/Light`, `amber/Light`, `coral/Light` | Success / Warning / Error |
| **Alias** | `primary`, `primaryLight`, `primaryDark`, `secondary`, `secondaryLight`, `error`, `warning`, `success`, `info` | Semantic aliases |
| **Booking** | `hold`, `confirmed`, `cancelled`, `completed`, `available` | Booking status |
| **Room** | `vacant/Bg`, `booked/Bg`, `occupied/Bg`, `maintenance/Bg` | Room status |
| **Extra** | `brownDark`, `greenDark`, `greenForest`, `purple`, `blueWeekday`, `orangeHoliday` | Accent colors |
| **Dark theme** | `darkContainer`, `darkBorder`, `darkHint`, `darkError`, `darkOnSurface`, `darkSecondaryContainer`, `darkOnSecondaryContainer` | Dark mode only |

Khi cần màu mới: thêm vào `AppColors` trước, rồi dùng ở UI.

### Shared Helpers — AppHelpers (QUAN TRỌNG)

**KHÔNG duplicate logic.** Dùng `AppHelpers` trong `lib/core/utils/helpers.dart`:

```dart
import '../../core/utils/helpers.dart';

// Role
AppHelpers.roleLabel('ADMIN')     // → 'Admin'
AppHelpers.roleLabel('STAFF')     // → 'Nhân viên'
AppHelpers.roleLabel('CUSTOMER')  // → 'Khách hàng'
AppHelpers.roleColor('STAFF')     // → AppColors.ocean
AppHelpers.roleColor('CUSTOMER')  // → AppColors.teal

// Booking status
AppHelpers.bookingStatusColor('HOLD')  // → AppColors.hold

// Price
AppHelpers.formatPrice(1500000)        // → '1.5tr'
AppHelpers.formatPriceTotal(500000, 3) // → '1.5tr'

// Date
AppHelpers.vietnameseDayOfWeek(1)      // → 'Thứ Hai'
```

Khi thêm logic mới dùng ở >= 2 nơi: thêm vào `AppHelpers`, KHÔNG copy-paste.

### Phone Input — `PhoneInput` (lib/core/utils/phone_input.dart)

**SĐT VN: max 10 chữ số, bắt đầu bằng `0`.** Mọi field nhập SĐT (booking, profile,
admin tạo user...) PHẢI dùng `PhoneInput` — không tự viết regex/validator riêng.

```dart
import '../../core/utils/phone_input.dart';

TextFormField(
  keyboardType: TextInputType.phone,
  inputFormatters: PhoneInput.formatters,   // chỉ digit + max 10 + ép ký tự đầu = 0
  validator: PhoneInput.validate,           // hoặc validateOptional cho field optional
  decoration: const InputDecoration(
    hintText: '0xxxxxxxxx (10 số)',
    counterText: '',                        // ẩn counter "X/10"
  ),
);
```

| Method | Khi nào |
|---|---|
| `PhoneInput.formatters` | Mọi `TextField/TextFormField` SĐT |
| `PhoneInput.validate` | Field bắt buộc (auth/register, profile, admin user form) |
| `PhoneInput.validateOptional` | Field có thể rỗng (vd booking customer phone) |
| `PhoneInput.isValid(value)` | Check nhanh không cần message |

### Shared Widgets — `lib/shared/widgets/` (QUAN TRỌNG)

**Widget dùng chung PHẢI đặt trong `shared/widgets/`**, KHÔNG viết private widget (`_WidgetName`) trong file view.

| Widget | File | Mô tả |
|---|---|---|
| `AppScaffold` | `app_scaffold.dart` | Scaffold chung (AppBar, BottomNav, theme) |
| `LoadingWidget`, `SkeletonList`, `EmptyStateWidget`, `ErrorStateWidget`, `AppSnackBar` | `loading_widget.dart` | Loading, skeleton, empty, error, snackbar |
| `SectionLabel` | `section_label.dart` | Nhãn section (11px, uppercase, muted) |
| `FilterChipTile` | `filter_chip_tile.dart` | Chip filter có icon + check |
| `DatePickerTile` | `date_picker_tile.dart` | Ô chọn ngày (label + value + calendar icon) |
| `GuestCounter` | `guest_counter.dart` | Bộ đếm +/- (người lớn, trẻ em, số lượng) |

---

## 10. CODE PATTERNS — Reference

### Models

```dart
@JsonSerializable()
class RoomModel extends Equatable {
  final String id;
  final String name;
  final double price;

  const RoomModel({required this.id, required this.name, required this.price});

  factory RoomModel.fromJson(Map<String, dynamic> json) => _$RoomModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoomModelToJson(this);

  @override
  List<Object?> get props => [id, name, price];
}
```

- `@JsonSerializable()` + generate `.g.dart`
- Extend `Equatable` + implement `props`
- Fields `final`; `const` constructor
- `@JsonKey(name: 'snake_case')` nếu API trả snake_case

### Repositories — Data Layer

```dart
class RoomRepository {
  final Dio _dio = ApiClient.instance;

  Future<ApiResponse<List<RoomModel>>> getRooms({String? homestayId}) async {
    try {
      final response = await _dio.get(ApiConstants.rooms, queryParameters: {
        if (homestayId != null) 'homestayId': homestayId,
      });
      final data = (response.data['data'] as List)
          .map((e) => RoomModel.fromJson(e))
          .toList();
      return ApiResponse.success(data);
    } on DioException catch (e) {
      return ApiResponse.error(e.response?.data['message'] ?? 'Lỗi kết nối');
    }
  }
}
```

- Repository chỉ gọi API và parse data — **không chứa business logic**
- Luôn return `ApiResponse<T>` — **không throw exception**
- Dùng `ApiClient.instance` (Dio singleton đã có auth interceptor)

#### Ngoại lệ — Feature-specific repository có abstract throw-style

Một vài feature có repository abstract định nghĩa `Future<T>` (throw on error)
thay vì `Future<ApiResponse<T>>`. Lý do: feature ra đời với mock-first approach,
controller bắt exception trực tiếp ở UI để hiện snackbar. Hiện đang dùng:

| Feature | Abstract | Real impl | Mock impl |
|---|---|---|---|
| `verify` (KYC) | `VerifyRepository` (throws `VerifyApiException`) | `VerifyRepositoryImpl` | `MockVerifyRepository` |
| `admin/kyc` | `AdminKycRepository` (throws `Exception`) | `AdminKycRepositoryImpl` | `MockAdminKYCRepository` |

Quy tắc khi sửa hoặc thêm method vào các feature này:
- **Real impl** PHẢI throw cùng exception type với abstract — KHÔNG đổi sang `ApiResponse`
- **Provider mặc định** trỏ real impl; QA override bằng `*.overrideWithValue(MockX())`
- Caller (UI) catch + extract message: `e.toString().replaceAll('Exception: ', '')`

Feature mới (room, booking, homestay, user...) PHẢI follow ApiResponse pattern
chuẩn — không tạo thêm throw-style abstract.

### Controllers — State Management (Riverpod)

#### Provider types

| Type | Khi nào dùng |
|---|---|
| `Provider` | Giá trị sync không đổi (repository instance) |
| `FutureProvider.family` | Fetch data từ API (list, detail) |
| `StateNotifierProvider` | State phức tạp + methods (actions: create, update, delete) |

#### Pattern chuẩn

```dart
// Repository provider
final roomRepositoryProvider = Provider<RoomRepository>((ref) => RoomRepository());

// List provider (FutureProvider.family cho filter)
final roomListProvider = FutureProvider.family<List<RoomModel>, String?>((ref, homestayId) async {
  final repo = ref.read(roomRepositoryProvider);
  final result = await repo.getRooms(homestayId: homestayId);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// Actions notifier (StateNotifier cho mutations)
class BookingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  BookingActionsNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> hold(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.holdRoom(data);
    if (result.success) {
      _ref.invalidate(bookingListProvider(null)); // ← Invalidate để UI re-fetch
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}
```

#### ref rules

- `ref.watch` — trong `build()`, reactive
- `ref.read` — trong event handlers/callbacks, KHÔNG trong `build()`
- `ref.listen` — side effects (navigation, snackbar)
- Sau mutation: `ref.invalidate(provider)` để re-fetch
- Dùng `select()` để giảm rebuild:

```dart
// ✅ Chỉ rebuild khi role thay đổi
final isAdmin = ref.watch(currentUserProvider.select((u) => u?.isAdmin ?? false));
```

### Views — UI Layer

```dart
class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomListProvider(null));
    return roomsAsync.when(
      data: (rooms) => ListView(...),
      loading: () => SkeletonList(skeleton: const RoomCardSkeleton()),
      error: (e, _) => ErrorStateWidget(
        message: e.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(roomListProvider),
      ),
    );
  }
}
```

#### UI Conventions

- `AppScaffold` thay vì `Scaffold` trực tiếp
- `LoadingWidget` / `SkeletonList` cho loading
- `EmptyStateWidget` cho empty state
- `ErrorStateWidget` cho error + retry
- `AppSnackBar.success/error/info(context, message)` cho notifications
- `CachedNetworkImage` cho tất cả image từ URL (luôn set `memCacheWidth`)
- Text tiếng Việt trực tiếp (không dùng i18n key)

### Navigation — GoRouter

```dart
context.go('/rooms');           // Replace stack (main navigation)
context.push('/rooms/$id');     // Push (overlay/detail)
context.pop();                  // Go back
```

#### Role-based routing

| Role | Redirect sau login | Bottom Nav |
|-------------|-------------------|------------|
| CUSTOMER (3) | `/home` | Trang chủ, Tìm phòng, Booking, Tài khoản |
| SALE (2) | `/dashboard` | Tổng quan, Phòng, Lịch, Báo cáo |
| OWNER (1) | `/dashboard` | Tổng quan, Phòng, Lịch, Báo cáo, Quản lý |
| ADMIN (0) | `/dashboard` | Tổng quan, Phòng, Lịch, Báo cáo, Quản lý |
| ADMIN/OWNER (mode khách) | `/home` | Giống CUSTOMER |

#### Route guard

```
CUSTOMER → chặn /dashboard, /rooms, /calendar, /homestays, /admin → redirect /home
SALE → chặn /admin → redirect /dashboard
ADMIN/OWNER (mode khách) → chặn management routes → redirect /home
ADMIN/OWNER (mode quản lý) → chặn customer routes → redirect /dashboard
OWNER chưa KYC approved → chặn /properties/new + /properties/:id/* → redirect /verify/cccd-front
```

→ KYC guard chỉ block các sub-route mutate (tạo/sửa). `/properties` (list) vẫn
truy cập được để user thấy banner CTA + verify status.

#### View Mode Toggle — QUAN TRỌNG trong GoRouter redirect

```dart
// ✅ ĐÚNG — tính trực tiếp
final user = authState.user;
final bool isCustomerMode;
if (user != null && user.isCustomer) {
  isCustomerMode = true;
} else if (user != null && user.isManagement) {
  isCustomerMode = ref.read(viewModeProvider) == ViewMode.customer;
} else {
  isCustomerMode = false;
}

// ❌ SAI — provider chain chưa kịp update
final isCustomerMode = ref.read(isCustomerModeProvider);
```

### API Integration

- Endpoints khai báo trong `lib/core/constants/api_constants.dart`
- Response format: `{ "success": true, "data": { ... }, "message": "..." }`
- Token tự động gắn bởi `_AuthInterceptor` trong `ApiClient`
- Auto-refresh token khi 401
- Token lưu qua `SecureStorage` (KHÔNG dùng SharedPreferences)
- Role system: **4 roles** — `ADMIN=0`, `OWNER=1`, `SALE=2`, `CUSTOMER=3`
  (helper getter trên `UserModel`: `isAdmin/isOwner/isSale/isCustomer`,
  composite: `isManagement = ADMIN || OWNER || SALE`,
  `canManageProperty = ADMIN || OWNER`)

### Backend-enforced business rules (frontend mirror)

Các rule sau backend áp đặt → frontend phải mirror để UX nhất quán:

| Rule | Backend trả | Frontend mirror |
|---|---|---|
| OWNER chưa KYC → không tạo/sửa property | `403 code=kyc.propertyRequiresKyc` | Route guard `user.needsKyc` redirect `/verify/cccd-front`; nếu vẫn lọt → `handleFeatureLocked` CTA xác minh |
| OWNER hết trial / chưa mua gói → không tạo/sửa property, mời NV | `403 code=subscription.featureLocked` | `handleFeatureLocked` toast + CTA "Mua gói" (xem §14) |
| OWNER trong silent trial (60d, chưa plan) | `subscriptionStatus='trial'`, `planId=null` | `isSilentTrial` → KHÔNG hard-block tạo phòng; cho mời 1 SALE (BE gate phần dư) |
| SALE chưa được OWNER assign → không CRUD property | `403` | UI lock + banner "Chưa được gán" trên dashboard |
| OWNER KYC pending → app chỉ cho dùng verify flow | `kycStatus = 'pending'` | Banner "Đang chờ duyệt", các route mutate vẫn lock |
| Subscription `past_due` | `subscriptionStatus = 'past_due'` | Banner đỏ + bottom sheet → /profile/help |

### Google Sign-In

- Flow: `GoogleSignIn.signIn()` → `idToken` → `/auth/google` → tokens + user
- Android: `google-services.json` + Firebase Console
- iOS: `GoogleService-Info.plist` + URL scheme trong `Info.plist`

---

## 11. PERFORMANCE & OPTIMIZATION

### Image — Giảm RAM

```dart
// ✅ ĐÚNG — luôn set memCacheWidth
CachedNetworkImage(
  imageUrl: url,
  fit: BoxFit.cover,
  memCacheWidth: 400,       // thumbnail / card
  placeholder: (_, __) => _placeholder(),
  errorWidget: (_, __, ___) => _placeholder(),
)
```

| Ngữ cảnh | memCacheWidth |
|-----------|:------------:|
| Card thumbnail | `400` |
| Search list card | `250` |
| Full-width detail | `800` |
| Gallery / zoom | Không set |

### ListView — Lazy loading

- Dùng `ListView.builder` / `SliverList` — KHÔNG dùng `Column` + `map`
- TabBarView + ListView → `AutomaticKeepAliveClientMixin`
- Danh sách > 20 items → phân trang (`?page=1&limit=20`)

### Search — Debounce 300ms

```dart
Timer? _debounce;
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    if (mounted) setState(() => _query = value);
  });
}
```

### Animation

| Quy tắc | Giá trị |
|---------|---------|
| Max effects per item | 2 (fadeIn + slideY) |
| Max stagger items | 5-6 |
| Duration | 200-400ms |
| Loading skeleton | Chỉ shimmer, không animate |

### Memory — Dispose checklist

```dart
@override
void dispose() {
  _textController.dispose();
  _scrollController.dispose();
  _focusNode.dispose();
  _animationCtrl.dispose();
  _debounce?.cancel();
  _timer?.cancel();
  _sub?.cancel(); // StreamSubscription
  super.dispose();
}
```

- Check `mounted` trước setState trong async callback
- Không `invalidate()` trong `build()`
- Không invalidate từ nhiều nguồn cùng lúc

---

## 12. TESTING

| Loại | Công cụ | Khi nào |
|------|---------|--------|
| Unit test | `flutter_test` + `mocktail` | Models, helpers, controllers, providers |
| Widget test | `flutter_test` | Shared widgets, form validation |
| Integration test | `integration_test` | Critical flows (login, booking) |

```bash
flutter test                                    # Tất cả
flutter test test/models/user_model_test.dart   # 1 file
flutter test --coverage                         # Coverage
```

```
test/
  models/           # Model fromJson, toJson, helpers
  helpers/          # AppHelpers methods
  constants/        # Enum values, fromString, labels
  providers/        # StateNotifier logic, persistence
  controllers/      # Business logic, filter models
  widgets/          # Widget rendering tests
```

---

## 13. LINTING & CODE GENERATION

```bash
flutter analyze
dart format .
dart run build_runner build --delete-conflicting-outputs
```

Không suppress lint warning trừ khi có lý do rõ ràng.

---

## 14. KYC + SUBSCRIPTION (feature `verify`)

### Overview

**Apple IAP compliance (BE v1.12 — repo này Android-only, iOS ở codebase khác):**

OWNER mới đăng ký → BE **tự cấp trial 60 ngày** (`subscriptionStatus="trial"`,
`trialEndsAt = now+60d`, **chưa gắn `subscriptionPlanId`**). Trong 60 ngày OWNER
**bắt buộc hoàn thành KYC** (upload CCCD trước/sau + selfie liveness → admin duyệt)
rồi mới dùng được tính năng quản lý: tạo property + **mời 1 SALE**. Hết 60 ngày
(hoặc trial không hợp lệ) → BE trả **403** ở write endpoint → user phải **mua gói**
(Android giữ flow thanh toán VietQR/select-plan; iOS không có UI thanh toán).

→ Chi tiết: [`docs/RELEASE_NOTES_v1.12_APPLE_IAP.md`](docs/RELEASE_NOTES_v1.12_APPLE_IAP.md)
+ [`docs/API_SPEC_FULL.md`](docs/API_SPEC_FULL.md) §2A.5.
→ Spec backend đầy đủ: [`API.md`](API.md) — section 14 (KYC User) + 15 (KYC Admin) + 16 (Billing & Payment)

### Entitlement gate (403 business codes — v1.12)

3 write endpoint trả **403 kèm field `code`** khi OWNER chưa đủ quyền:
`POST /properties`, `PATCH /properties/:id`, `POST /staff/invites`.

| `code` | Ý nghĩa | FE xử lý |
|---|---|---|
| `subscription.featureLocked` | Hết trial / chưa mua gói / past_due / cancelled / frozen (generic, không lộ trạng thái) | Toast message BE + CTA "Mua gói" → `subscriptionPlanPickerRoute` |
| `kyc.propertyRequiresKyc` | OWNER chưa KYC approved | Toast + CTA "Xác minh ngay" → `/verify/cccd-front` |

**Plumbing**: `ApiResponse` mang `code` + `statusCode` (factory
`ApiResponse.fromDioError`, extension `isFeatureLocked`/`isKycRequired`,
constants `ApiErrorCodes`). Controller đẩy `ApiFailure`
(`lib/core/network/api_failure.dart`) qua `AsyncValue.error` để UI đọc được code.
Helper dùng chung: `handleFeatureLocked(context, ApiFailure, user)` trong
`lib/shared/widgets/feature_locked.dart`. KHÁC với `VerifyApiException`
(throw-style, riêng feature verify — giữ nguyên).

**Silent-trial entitlement (mirror BE)**: khi `isInTrial && subscriptionPlanId`
rỗng → `SubscriptionGating.isSilentTrial(user)` = true. Lúc này client KHÔNG
hard-block: `canAddMoreRooms` trả true (BE gate số phòng), `maxStaffInviteSlots`
= 1 (`trialDefaultStaffSlots`), `canInviteStaff` true. Gói trả phí vẫn theo
`RoomEntitlement`/`StaffEntitlement` như cũ (quota "Đã dùng 3/5 phòng" giữ nguyên).

### State machine — 7 status (camelCase, khớp giữa backend & frontend)

```
draft → kycSubmitted → paymentPending → awaitingApproval
   ↑                                       │
   │ resubmit                              ├─ approved   → trial → active
   │                                       └─ rejected → (resubmit) | refunded
```

Enum: `lib/features/verify/data/models/verify_enums.dart`. Backend gửi
camelCase, parse qua `verifyStatusFromApi()` trong `payment_session.dart`.

### Source of truth

- `user.kycStatus` (`none|pending|approved|rejected`) từ `/auth/profile` —
  dùng cho **dashboard banner + route guard** (persistent, sync với backend)
- `verifyFlowControllerProvider` — **local state** trong flow capture/payment
  (CCCD images chưa submit, selected plan...). Hydrate từ backend khi mở
  paywall: `ref.read(verifyFlowControllerProvider.notifier).hydrate()`

KHÔNG dùng `verifyFlowController.status` để gate UI ngoài verify flow — sẽ
drift khi user logout/login. Luôn dùng `user.kycStatus`.

### Auto-refresh user profile

Để bắt KYC/subscription change từ backend (vd admin vừa approve):

1. **App resume** — `WidgetsBindingObserver` ở `main.dart` gọi `refreshProfile()`
2. **Pull-to-refresh dashboard** — `ref.read(authProvider.notifier).refreshProfile()`
3. **Pending screen poll** — sau khi `checkApprovalStatus()` trả approved/rejected → refresh trước khi navigate

Khi backend implement FCM push, thêm 4. **FCM listener** invalidate
`currentUserProvider` khi nhận push `type=kyc_*`.

### Subscription helpers

`UserModel` có sẵn:
- `isInTrial` / `isSubscriptionActive` / `isSubscriptionPastDue` / `isSubscriptionCancelled`
- `trialDaysLeft` (int? — null nếu không trong trial)

Dashboard tự render banner cho 4 variant trên (xem `_SubscriptionBanner`),
tap → bottom sheet → `/profile/help` cho support.

### Khi sửa verify/admin-kyc code

- Real impl phải implement `VerifyRepository` / `AdminKycRepository` abstract — KHÔNG đổi sang ApiResponse pattern (xem Section 10 ngoại lệ)
- Mock pre-existed cho QA — giữ + maintain song song
- Models KYC (`cccd_upload`, `selfie_upload`, `ocr_result`, `plan`,
  `payment_session`) sống trong `features/verify/data/models/` — admin import
  cross-feature là chấp nhận được vì admin chỉ review data verify tạo ra
  (KHÔNG sao chép models ra `data/models/`)
- Phone backend trả snake_case (`vnpay_qr`, `bank_transfer`) → map qua
  `_methodFromApi()` + `paymentStatusFromApi()` trong `payment_session.dart`
