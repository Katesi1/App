# Skill: Scaffolding — Tạo cấu trúc module/feature mới

## Khi nào dùng
- Tạo feature mới (VD: thêm module "reports", "notifications")
- Thêm CRUD cho entity mới
- Tạo screen/controller/repository mới

## Execution Flow

### Step 1: Xác định scope
- Entity/feature tên gì?
- Cần những screen nào?
- API endpoints nào? (check `ApiConstants` và Swagger docs)
- Có reuse được model/widget existing không?

### Step 2: Tạo folder structure

```
features/<feature_name>/
  controllers/
    <feature>_controller.dart
  views/
    <feature>_list_screen.dart
    <feature>_detail_screen.dart
    <feature>_form_screen.dart
  widgets/                        # Nếu có widget riêng cho feature
    <feature>_card.dart
```

### Step 3: Tạo theo thứ tự (QUAN TRỌNG)

Luôn tạo từ dưới lên — layer dưới không phụ thuộc layer trên:

```
1. Model          → data/models/<name>_model.dart
2. Repository     → data/repositories/<name>_repository.dart
3. Controller     → features/<name>/controllers/<name>_controller.dart
4. View           → features/<name>/views/<name>_screen.dart
5. Route          → core/utils/app_router.dart (thêm route)
6. Navigation     → shared/widgets/app_scaffold.dart (thêm bottom nav nếu cần)
```

### Step 4: Template cho từng layer

#### 4.1 Model Template

```dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part '<name>_model.g.dart';

@JsonSerializable()
class <Name>Model extends Equatable {
  final String id;
  // ... fields

  const <Name>Model({required this.id, ...});

  factory <Name>Model.fromJson(Map<String, dynamic> json) =>
      _$<Name>ModelFromJson(json);
  Map<String, dynamic> toJson() => _$<Name>ModelToJson(this);

  @override
  List<Object?> get props => [id, ...];
}
```

Sau khi tạo model: `dart run build_runner build --delete-conflicting-outputs`

#### 4.2 Repository Template

```dart
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/constants/api_constants.dart';
import '../models/<name>_model.dart';

class <Name>Repository {
  final Dio _dio = ApiClient.instance;

  Future<ApiResponse<List<Name>Model>> getAll({String? filter}) async {
    try {
      final response = await _dio.get(ApiConstants.<endpoint>, queryParameters: {
        if (filter != null) 'filter': filter,
      });
      final data = (response.data['data'] as List)
          .map((e) => <Name>Model.fromJson(e))
          .toList();
      return ApiResponse.success(data);
    } on DioException catch (e) {
      return ApiResponse.error(e.response?.data['message'] ?? 'Loi ket noi');
    }
  }

  Future<ApiResponse<Name>Model> getById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.<endpoint>}/$id');
      return ApiResponse.success(<Name>Model.fromJson(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(e.response?.data['message'] ?? 'Loi ket noi');
    }
  }

  Future<ApiResponse<void>> create(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.<endpoint>, data: data);
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(e.response?.data['message'] ?? 'Loi ket noi');
    }
  }
}
```

#### 4.3 Controller Template

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/<name>_repository.dart';
import '../../../data/models/<name>_model.dart';

// Repository provider
final <name>RepositoryProvider = Provider<Name>Repository>((ref) => <Name>Repository());

// List provider
final <name>ListProvider = FutureProvider.family<List<<Name>Model>, String?>((ref, filter) async {
  final repo = ref.read(<name>RepositoryProvider);
  final result = await repo.getAll(filter: filter);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// Actions notifier
class <Name>ActionsNotifier extends StateNotifier<AsyncValue<void>> {
  <Name>ActionsNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));
  final <Name>Repository _repo;
  final Ref _ref;

  Future<bool> create(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.create(data);
    if (result.success) {
      _ref.invalidate(<name>ListProvider(null));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final <name>ActionsProvider = StateNotifierProvider<<Name>ActionsNotifier, AsyncValue<void>>((ref) {
  return <Name>ActionsNotifier(ref.read(<name>RepositoryProvider), ref);
});
```

#### 4.4 View Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/<name>_controller.dart';
import '../../../shared/widgets/loading_widget.dart';

class <Name>ListScreen extends ConsumerWidget {
  const <Name>ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(<name>ListProvider(null));
    return dataAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateWidget(message: 'Chua co du lieu');
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => _buildItem(items[i]),
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorStateWidget(
        message: e.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(<name>ListProvider(null)),
      ),
    );
  }
}
```

### Step 5: Thêm API endpoint

Mở `lib/core/constants/api_constants.dart` và thêm:

```dart
static const String <name>s = '/<name>s';
static const String <name>Detail = '/<name>s/'; // + id
```

### Step 6: Thêm route

Mở `lib/core/utils/app_router.dart` và thêm GoRoute.

### Step 7: Chạy verification

- [ ] `flutter analyze` — không có error
- [ ] `dart format .` — format OK
- [ ] `dart run build_runner build` — nếu thêm model
- [ ] `flutter test` — không break test existing

## Checklist trước khi done

- [ ] Folder structure đúng MVC?
- [ ] Model có `@JsonSerializable`, `Equatable`, `const` constructor?
- [ ] Repository dùng `ApiClient.instance`, return `ApiResponse`?
- [ ] Controller dùng đúng provider type?
- [ ] View dùng `ConsumerWidget`, handle loading/error/empty?
- [ ] Route đã thêm vào `app_router.dart`?
- [ ] Không import chéo feature khác?
- [ ] `const` ở mọi nơi có thể?
