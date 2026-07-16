import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../data/models/user_permission.dart';
import '../data/repositories/permission_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final permissionRepositoryProvider = Provider<PermissionRepository>(
  (ref) => PermissionRepository(),
);

// ─── Danh sách SALE hệ thống (ADMIN) ─────────────────────────────────────────
final systemSaleListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 2), link.close);
  ref.onDispose(timer.cancel);
  final repo = ref.watch(permissionRepositoryProvider);
  final result = await repo.listSystemStaff();
  if (result.success) {
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  }
  throw Exception(result.message);
});

// ─── Quyền của 1 user ────────────────────────────────────────────────────────
final userPermissionsProvider = FutureProvider.autoDispose
    .family<List<UserPermission>, String>((ref, userId) async {
  final repo = ref.watch(permissionRepositoryProvider);
  final result = await repo.getPermissions(userId);
  if (result.success) {
    return result.data ?? (throw Exception('Dữ liệu trả về trống'));
  }
  throw Exception(result.message);
});

// ─── Action lưu quyền (PUT) ──────────────────────────────────────────────────
class PermissionSaveNotifier extends StateNotifier<AsyncValue<void>> {
  final PermissionRepository _repo;
  final Ref _ref;

  PermissionSaveNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> save(String userId, List<UserPermission> permissions) async {
    state = const AsyncValue.loading();
    final result = await _repo.updatePermissions(userId, permissions);
    if (result.success) {
      _ref.invalidate(userPermissionsProvider(userId));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final permissionSaveProvider =
    StateNotifierProvider<PermissionSaveNotifier, AsyncValue<void>>((ref) {
  return PermissionSaveNotifier(ref.read(permissionRepositoryProvider), ref);
});
