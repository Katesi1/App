# CLAUDE.md — Homestay Management App

Tài liệu này định nghĩa conventions và standards để AI (Claude Code) và dev luôn code nhất quán cho dự án này.

---

## Project Overview

- **App**: Homestay Management Mobile App (Halong24h)
- **Architecture**: MVC (Model - View - Controller) với Riverpod
- **Platform**: Flutter (iOS + Android)
- **Backend API**: `http://103.183.118.148:3000`
- **Swagger docs**: `http://103.183.118.148/index.html`

---

## Tech Stack

| Thành phần | Package |
|---|---|
| UI Framework | Flutter SDK + Material Design 3 |
| Language | Dart 3.5+ |
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

## Project Structure (MVC)

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
      user_model.dart            # UserModel (role helpers: isAdmin, isOwner, canEdit)
      room_model.dart            # RoomModel, RoomImageModel, RoomPriceModel, HomestaySimpleModel
      homestay_model.dart        # HomestayModel
      booking_model.dart         # BookingModel, CalendarBooking
    repositories/
      auth_repository.dart       # Login (phone/password + Google), logout, token management
      user_repository.dart       # CRUD users
      room_repository.dart       # CRUD rooms, images, prices
      homestay_repository.dart   # CRUD homestays
      booking_repository.dart    # CRUD bookings, calendar, hold/confirm/cancel

  features/                      # Feature modules (MVC per feature)
    auth/
      controllers/
        auth_controller.dart     # AuthNotifier, authProvider, currentUserProvider
      views/
        login_screen.dart        # Login form + Google Sign-In
        splash_screen.dart       # Splash animation + auto-redirect
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
      views/
        user_list_screen.dart
        user_form_screen.dart

  shared/                        # Code dùng chung giữa các features
    providers/
      theme_provider.dart        # ThemeNotifier (light/dark, persist SharedPreferences)
    widgets/
      app_scaffold.dart          # AppScaffold (AppBar + BottomNav + theme toggle + user menu)
      loading_widget.dart        # LoadingWidget, Skeletons, EmptyStateWidget, ErrorStateWidget, AppSnackBar

  main.dart                      # ProviderScope → MaterialApp.router
```

### Quy tắc thư mục

- **MVC per feature**: Mỗi feature có `controllers/` (state + logic), `views/` (UI screens), `widgets/` (reusable UI components)
- **Không import chéo giữa features** — dùng `shared/` hoặc `core/` cho code dùng chung
- **Controllers** đặt trong `features/<feature>/controllers/`
- **Data flow**: unidirectional — UI → event → Controller → Repository → API → Controller → UI rebuild

---

## Dart / Flutter Code Style

- **Naming**: `UpperCamelCase` cho class/type, `lowerCamelCase` cho biến/hàm, `lowercase_with_underscores` cho file
- **Files**: Mỗi file một class/widget chính; tên file = tên class (snake_case)
- **Imports**: Relative imports; nhóm theo: dart → flutter → packages → local
- **Formatting**: `dart format`; line limit 80 ký tự
- **Control flow**: Luôn dùng curly braces `{}`
- **Variables**: Ưu tiên `final` > `var`; dùng `const` khi có thể
- **Types**: Annotate return type và parameter khi type không hiển nhiên
- **Async/await** thay vì `.then()` chains

### Dart 3 Features

- **Records** cho multiple return values
- **Patterns** cho destructure
- **Switch expressions** cho control flow ngắn gọn
- **Sealed classes** + `switch` cho exhaustiveness
- **if-case** + `when` guard clause

---

## Colors — AppColors (QUAN TRỌNG)

**KHÔNG BAO GIỜ hardcode `Color(0xFF...)` trong code.** Tất cả màu phải khai báo trong `lib/core/theme/app_colors.dart`.

```dart
// ✅ ĐÚNG
color: AppColors.ocean
color: AppColors.brownDark

// ❌ SAI — hardcode color
color: Color(0xFF92400E)
color: const Color(0xFF1976D2)
```

### Danh sách màu có sẵn

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

---

## Shared Helpers — AppHelpers (QUAN TRỌNG)

**KHÔNG duplicate logic.** Dùng `AppHelpers` trong `lib/core/utils/helpers.dart`:

```dart
import '../../core/utils/helpers.dart';

// Role
AppHelpers.roleLabel('ADMIN')     // → 'Admin'
AppHelpers.roleColor('OWNER')     // → AppColors.completed

// Booking status
AppHelpers.bookingStatusColor('HOLD')  // → AppColors.hold

// Price
AppHelpers.formatPrice(1500000)        // → '1.5tr'
AppHelpers.formatPriceTotal(500000, 3) // → '1.5tr'

// Date
AppHelpers.vietnameseDayOfWeek(1)      // → 'Thứ 2'
```

Khi thêm logic mới dùng ở >= 2 nơi: thêm vào `AppHelpers`, KHÔNG copy-paste.

---

## Controllers — State Management (Riverpod)

Controllers đặt trong `features/<feature>/controllers/`. Dùng Riverpod providers.

### Provider types

| Type | Khi nào dùng |
|---|---|
| `Provider` | Giá trị sync không đổi (repository instance) |
| `FutureProvider.family` | Fetch data từ API (list, detail) |
| `StateNotifierProvider` | State phức tạp + methods (actions: create, update, delete) |

### Pattern chuẩn cho Controller

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

### ref rules

- `ref.watch` — trong `build()`, reactive
- `ref.read` — trong event handlers/callbacks, KHÔNG trong `build()`
- `ref.listen` — side effects (navigation, snackbar)
- Sau mutation: `ref.invalidate(provider)` để re-fetch

---

## Views — UI Layer

Views đặt trong `features/<feature>/views/`. Chứa **minimal logic** — chỉ UI.

### Widget pattern

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

### UI Conventions

- `AppScaffold` thay vì `Scaffold` trực tiếp (có AppBar, BottomNav, theme toggle)
- `LoadingWidget` cho loading spinner
- `SkeletonList` + `*CardSkeleton` cho shimmer loading
- `EmptyStateWidget` cho empty state
- `ErrorStateWidget` cho error + retry
- `AppSnackBar.success/error/info(context, message)` cho notifications
- `CachedNetworkImage` cho tất cả image từ URL
- Text tiếng Việt trực tiếp (không dùng i18n key)
- Theme colors/styles lấy từ `AppColors` — **KHÔNG hardcode**

---

## Repositories — Data Layer

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

---

## Models

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

---

## Navigation — GoRouter

```dart
context.go('/rooms');           // Replace stack (main navigation)
context.push('/rooms/$id');     // Push (overlay/detail)
context.push('/rooms/$id/edit');
context.pop();                  // Go back
```

- Route paths: lowercase, `/admin/users`, `/rooms/:id/edit`
- Auth redirect logic trong `app_router.dart` — tự redirect `/login` ↔ `/dashboard`

---

## API Integration

### Endpoints

Tất cả endpoints khai báo trong `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://103.183.118.148:3000';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  // ... thêm endpoint mới tại đây
}
```

### Response format

```json
{ "success": true, "data": { ... }, "message": "..." }
```

Parse: `response.data['data']` cho data, `response.data['message']` cho message.

### Auth

- Token tự động gắn header bởi `_AuthInterceptor` trong `ApiClient`
- Auto-refresh token khi 401
- Login hỗ trợ: phone/password + Google Sign-In
- Token lưu qua `SecureStorage` (KHÔNG dùng SharedPreferences cho token)

---

## Google Sign-In

Package: `google_sign_in: ^6.2.2`

- Flow: `GoogleSignIn.signIn()` → lấy `idToken` → gửi lên backend `/auth/google` → nhận tokens + user
- Cấu hình cần thiết:
  - **Android**: `android/app/google-services.json` + Firebase Console
  - **iOS**: `GoogleService-Info.plist` + URL scheme trong `Info.plist`

---

## Linting & Code Generation

```bash
# Analyze
flutter analyze

# Format
dart format .

# Code gen (sau khi thêm/sửa model hoặc @riverpod annotation)
dart run build_runner build --delete-conflicting-outputs
```

Không suppress lint warning trừ khi có lý do rõ ràng.

---

## Quy tắc quan trọng

1. **KHÔNG hardcode Color()** — luôn dùng `AppColors.*`
2. **KHÔNG duplicate logic** — dùng `AppHelpers` cho hàm dùng chung
3. **KHÔNG hardcode Base URL** — luôn dùng `ApiConstants.baseUrl`
4. **KHÔNG dùng `setState` trong ConsumerWidget** — dùng Riverpod state
5. **KHÔNG throw exception từ Repository** — dùng `ApiResponse.error()`
6. **KHÔNG import chéo giữa features** — dùng `shared/` hoặc `core/`
7. **KHÔNG tự tạo Dio instance** — luôn dùng `ApiClient.instance`
8. **Đặt const ở mọi nơi có thể** — widget, constructor, giá trị cố định
9. **Async/await** thay vì `.then()` chains
10. **Thêm feature mới**: tạo folder trong `features/<name>/` với `controllers/`, `views/`, `widgets/` (nếu cần)
