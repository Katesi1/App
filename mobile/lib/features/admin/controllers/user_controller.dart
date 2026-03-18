import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

// ─── List provider (optional role filter) ────────────────────────────────────
final userListProvider =
    FutureProvider.family<List<UserModel>, String?>((ref, role) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getUsers(role: role);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── Detail provider ──────────────────────────────────────────────────────────
final userDetailProvider =
    FutureProvider.family<UserModel, String>((ref, id) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getUser(id);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

// ─── Actions notifier ─────────────────────────────────────────────────────────
class UserActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repo;
  final Ref _ref;

  UserActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> create(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.createUser(data);
    if (result.success) {
      _ref.invalidate(userListProvider(null));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateUser(id, data);
    if (result.success) {
      _ref.invalidate(userListProvider(null));
      _ref.invalidate(userDetailProvider(id));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.deleteUser(id);
    if (result.success) {
      _ref.invalidate(userListProvider(null));
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final userActionsProvider =
    StateNotifierProvider<UserActionsNotifier, AsyncValue<void>>((ref) {
  return UserActionsNotifier(
    ref.read(userRepositoryProvider),
    ref,
  );
});
