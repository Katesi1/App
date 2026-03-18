# CLAUDE.md — Homestay Management App

Tài liệu này định nghĩa conventions và standards để AI (Claude Code) luôn code nhất quán cho dự án này.

---

## Project Overview

- **App**: Homestay Management Mobile App
- **Platform**: Flutter (iOS + Android)
- **Backend API**: `http://103.183.118.148/api/v1`
- **Swagger docs**: `http://103.183.118.148/index.html`

---

## Tech Stack

| Thành phần | Package |
|---|---|
| UI Framework | Flutter SDK + Material Design |
| Language | Dart 3.5+ |
| State Management | `flutter_riverpod ^2.6.1` + `riverpod_annotation` + `riverpod_generator` |
| Navigation | `go_router ^14` |
| HTTP Client | `dio ^5` |
| Secure Storage | `flutter_secure_storage` |
| Local Prefs | `shared_preferences` |
| JSON | `json_annotation` + `json_serializable` |
| Equality | `equatable` |
| Linting | `flutter_lints` + `riverpod_lint` + `custom_lint` |

---

## Project Structure

```
lib/
  core/
    constants/       # ApiConstants, AppConstants
    network/         # ApiClient (Dio), ApiResponse
    storage/         # SecureStorage
    theme/           # AppTheme
    utils/           # AppRouter (GoRouter provider)
  data/
    models/          # JSON-serializable models
    repositories/    # Data access layer
  features/
    auth/
      screens/
    admin/
      screens/
    bookings/
      screens/
    homestays/
      screens/
    rooms/
      providers/     # Riverpod providers
      screens/
      widgets/
  shared/
    providers/       # authProvider, routerProvider
    widgets/         # AppScaffold, LoadingWidget
  main.dart
```

**Quy tắc thư mục** (nguồn: [flutter_app_architecture](https://github.com/evanca/flutter-ai-rules/blob/main/rules/flutter_app_architecture.md)):
- Kiến trúc phân tầng: **UI layer** → **Data layer** (không skip tầng)
- Mỗi feature là một thư mục độc lập: `screens/`, `widgets/`, `providers/`
- Không import chéo giữa các features — dùng `shared/` cho code dùng chung
- Providers đặt trong `features/<feature>/providers/` hoặc `shared/providers/`
- Repositories là single source of truth — handle caching và error management
- Views (Screens) chứa minimal logic — chỉ UI
- Data flow: state flows từ data layer → UI layer; events từ UI → ngược lại (unidirectional)

---

## Dart / Flutter Code Style

Nguồn: [Effective Dart](https://dart.dev/effective-dart) + [flutter-ai-rules/effective_dart](https://github.com/evanca/flutter-ai-rules/blob/main/rules/effective_dart.md)

- **Naming**: `UpperCamelCase` cho class/type, `lowerCamelCase` cho biến/hàm, `lowercase_with_underscores` cho file/package
- **Files**: Mỗi file một class/widget chính; tên file = tên class (snake_case)
- **Imports**: Relative imports trong cùng package; nhóm theo thứ tự: dart → flutter → packages → local; không import từ thư mục `src/` của package khác
- **Formatting**: Luôn chạy `dart format`; line limit 80 ký tự
- **Control flow**: Luôn dùng curly braces `{}`
- **Variables**: Ưu tiên `final` > `var`; dùng `const` khi có thể; initialize fields at declaration khi có thể
- **Types**: Luôn annotate return type và parameter khi type không hiển nhiên; dùng `Future<void>` cho async không trả giá trị
- **Getters/Setters**: Dùng getter cho property access, setter cho property modification
- **Collections**: Dùng collection literals; dùng `whereType()` để filter theo type
- **Class modifiers**: Dùng `base`, `final`, `sealed`, `interface` để kiểm soát extension (Dart 3)
- **hashCode**: Override `hashCode` khi override `==`
- **Exceptions**: Dùng `rethrow` để rethrow exception đã catch

## Dart 3 Modern Features

Nguồn: [flutter-ai-rules/dart_3_updates](https://github.com/evanca/flutter-ai-rules/blob/main/rules/dart_3_updates.md)

- **Records**: Dùng để return nhiều giá trị từ function: `var (name, age) = userInfo(json);`
- **Patterns**: Dùng để destructure records, lists, objects: `var (a, [b, c]) = ('str', [1, 2]);`
- **Switch expressions**: Dùng cho exhaustive control flow ngắn gọn
- **Sealed classes**: Dùng với `switch` để đảm bảo exhaustiveness
- **if-case**: Dùng để match và destructure: `if (pair case [int x, int y]) { ... }`
- **Guard clause**: Dùng `when` trong switch/if-case để thêm điều kiện: `case pattern when condition:`

---

## Riverpod — State Management

Nguồn: [flutter-ai-rules/riverpod](https://github.com/evanca/flutter-ai-rules/blob/main/rules/riverpod.md) + [flutter-ai-rules/combined](https://github.com/evanca/flutter-ai-rules/blob/main/combined/flutter_with_riverpod__under_6K.md)

### Provider types — dùng đúng loại

- `Provider` — giá trị sync không thay đổi
- `StateProvider` — state đơn giản, UI có thể sửa trực tiếp
- `FutureProvider` — async operation (API call)
- `StreamProvider` — real-time data stream
- `NotifierProvider` — state phức tạp với methods
- `AsyncNotifierProvider` — async state phức tạp với methods

### Quy tắc bắt buộc

```dart
// ✅ ĐÚNG — dùng @riverpod annotation + code gen
@riverpod
Future<List<RoomModel>> roomList(RoomListRef ref, String? homestayId) async {
  return ref.read(roomRepositoryProvider).getRooms(homestayId: homestayId);
}

// ✅ ĐÚNG — Notifier cho state phức tạp có methods
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => AuthState.initial();

  Future<void> login(String email, String password) async { ... }
}

// ❌ TRÁNH — manual Provider khi có thể dùng @riverpod
final someProvider = Provider<SomeClass>((ref) => SomeClass());
```

### Sử dụng ref — quan trọng

- `ref.watch` — trong `build()`, reactive, tự rebuild khi thay đổi
- `ref.read` — trong event handlers/callbacks, KHÔNG dùng trong `build()`
- `ref.listen` — side effects (navigation, snackbar) khi provider thay đổi
- Khi dùng `ref.watch` với async provider, dùng `.future` nếu cần await giá trị

### State updates sau side effect

Sau khi gọi API mutation, cập nhật UI bằng một trong ba cách:
1. Set state trực tiếp nếu server trả về data mới
2. `ref.invalidateSelf()` để re-fetch provider
3. Cập nhật local cache thủ công nếu server không trả data

### Auto Dispose

- Mặc định với code gen: state bị destroy khi provider không còn được listen
- Dùng `keepAlive: true` để giữ state
- **Bắt buộc** enable autoDispose cho provider nhận parameter (family) để tránh memory leak
- Dùng `ref.onDispose` để cleanup

### Widget pattern

```dart
// ✅ Dùng ConsumerWidget thay vì StatelessWidget khi cần provider
class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomListProvider(null));
    return roomsAsync.when(
      data: (rooms) => ...,
      loading: () => const LoadingWidget(),
      error: (e, _) => Text('Lỗi: $e'),
    );
  }
}
```

- `ProviderScope` phải wrap toàn bộ app ở `runApp` (đã có)
- Provider variables phải là `final` và khai báo ở top-level (global scope)
- Chạy `dart run build_runner build --delete-conflicting-outputs` sau khi thêm `@riverpod`
- Luôn import file `.g.dart` tương ứng

---

## Repositories — Data Layer

```dart
// Pattern chuẩn cho mọi repository
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

- Repository chỉ gọi API và parse data — không chứa business logic
- Luôn return `ApiResponse<T>` — không throw exception từ repository
- Dùng `ApiClient.instance` (Dio singleton đã có auth interceptor)

---

## Models

```dart
// ✅ Pattern chuẩn — json_serializable + equatable
@JsonSerializable()
class RoomModel extends Equatable {
  final String id;
  final String name;
  final double price;

  const RoomModel({required this.id, required this.name, required this.price});

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoomModelToJson(this);

  @override
  List<Object?> get props => [id, name, price];
}
```

- Luôn dùng `@JsonSerializable()` + generate `.g.dart`
- Extend `Equatable` và implement `props`
- Fields là `final`; dùng `const` constructor
- Dùng `@JsonKey(name: 'snake_case')` nếu API trả về snake_case

---

## Navigation — GoRouter

```dart
// ✅ Navigate bằng context.go / context.push
context.go('/rooms');
context.push('/rooms/$id');
context.push('/rooms/$id/edit');

// ✅ Pass params qua pathParameters hoặc queryParameters
GoRoute(
  path: ':id',
  builder: (_, state) => RoomDetailScreen(
    roomId: state.pathParameters['id']!,
  ),
),
```

- Route paths dùng lowercase hyphen: `/admin/users`, `/rooms/:id/edit`
- `context.go` cho navigation chính (replace stack), `context.push` cho overlay
- Route redirect logic đặt trong `routerProvider` (đã có trong `app_router.dart`)

---

## API Integration

### Base URL & Endpoints

```dart
// Tất cả endpoints khai báo trong ApiConstants
class ApiConstants {
  static const String baseUrl = 'http://103.183.118.148/api/v1';
  static const String login = '/auth/login';
  // ... thêm endpoint mới tại đây
}
```

### Response format

API trả về format chuẩn:
```json
{
  "success": true,
  "data": { ... },
  "message": "..."
}
```

Khi parse: luôn đọc `response.data['data']` cho data, `response.data['message']` cho message.

### Auth

- Token tự động gắn vào header bởi `_AuthInterceptor` trong `ApiClient`
- Auto-refresh token khi nhận 401 — đã xử lý trong interceptor
- Lưu/đọc token qua `SecureStorage` (không dùng SharedPreferences cho token)

---

## UI / Widget Conventions

- Dùng `AppScaffold` thay vì `Scaffold` trực tiếp (wrapper chung)
- Dùng `LoadingWidget` cho loading state thay vì tự viết `CircularProgressIndicator`
- Dùng `CachedNetworkImage` cho tất cả image từ URL
- Text tiếng Việt trực tiếp trong code (không dùng i18n key)
- Theme colors/styles lấy từ `AppTheme` — không hardcode màu

---

## Linting

Dự án dùng `flutter_lints` + `riverpod_lint`. Trước khi commit:

```bash
flutter analyze
dart format .
```

Không suppress lint warning trừ khi có lý do rõ ràng và comment giải thích.

---

## Code Generation

Sau khi thêm/sửa model hoặc provider có annotation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Các file `.g.dart` được generate — không sửa tay.

---

## Quy tắc quan trọng

1. **Không hardcode Base URL** — luôn dùng `ApiConstants.baseUrl`
2. **Không dùng `setState` trong ConsumerWidget** — dùng Riverpod state
3. **Không throw exception từ Repository** — dùng `ApiResponse.error()`
4. **Không import feature A từ feature B** — dùng `shared/`
5. **Không tự tạo Dio instance** — luôn dùng `ApiClient.instance`
6. **Đặt const ở mọi nơi có thể** — widget, constructor, giá trị cố định
7. **Async/await** thay vì `.then()` chains
