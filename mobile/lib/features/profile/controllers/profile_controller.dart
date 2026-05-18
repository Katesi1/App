import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';

final profileRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());

/// Profile update actions.
final profileActionsProvider =
    StateNotifierProvider<ProfileActionsNotifier, AsyncValue<void>>((ref) {
  return ProfileActionsNotifier(
    ref.read(profileRepositoryProvider),
    ref.read(authRepositoryProvider),
    ref,
  );
});

class ProfileActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _userRepo;
  final AuthRepository _authRepo;
  final Ref _ref;

  ProfileActionsNotifier(this._userRepo, this._authRepo, this._ref)
      : super(const AsyncValue.data(null));

  /// Update profile (name, email, phone).
  Future<bool> updateProfile(String userId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _userRepo.updateUser(userId, data);
    if (result.success && result.data != null) {
      await _authRepo.saveUserLocal(result.data!);
      _ref.read(authProvider.notifier).replaceUser(result.data!);
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  /// Change password.
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authRepo.changePassword(
      oldPassword,
      newPassword,
    );
    if (result.success) {
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}
