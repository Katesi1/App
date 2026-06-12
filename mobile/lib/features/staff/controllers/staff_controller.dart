import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../data/models/user_model.dart';
import '../data/models/staff_invite.dart';
import '../data/repositories/staff_repository.dart';

export '../data/repositories/staff_repository.dart'
    show AcceptInviteOutcome, AcceptInviteSuccess, AcceptInviteFailure;

final staffRepositoryProvider =
    Provider<StaffRepository>((ref) => StaffRepository());

/// Filter status cho `staffInvitesProvider`. UI dropdown set giá trị này.
final staffInviteFilterProvider =
    StateProvider<StaffInviteStatus?>((ref) => null);

/// List invite OWNER đã tạo. Re-fetch sau mỗi mutation qua `invalidate`.
final staffInvitesProvider =
    FutureProvider.autoDispose<List<StaffInvite>>((ref) async {
  final repo = ref.read(staffRepositoryProvider);
  final filter = ref.watch(staffInviteFilterProvider);
  final result = await repo.listInvites(status: filter);
  if (result.success) return result.data ?? const [];
  throw Exception(result.message);
});

/// List nhân viên (SALE) hiện tại của OWNER.
final staffListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.read(staffRepositoryProvider);
  final result = await repo.listStaff(isActive: true);
  if (result.success) return result.data ?? const [];
  throw Exception(result.message);
});

/// Mutations: invite/cancel/remove. Trả `(success, message)` để UI hiện snackbar.
class StaffActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final StaffRepository _repo;
  final Ref _ref;

  StaffActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<(bool, String, StaffInvite?)> invite(String email) async {
    state = const AsyncValue.loading();
    final result = await _repo.createInvite(email);
    if (result.success) {
      _ref.invalidate(staffInvitesProvider);
      state = const AsyncValue.data(null);
      return (true, result.message, result.data);
    }
    state = AsyncValue.error(
      ApiFailure(result.message,
          code: result.code, statusCode: result.statusCode),
      StackTrace.current,
    );
    return (false, result.message, null);
  }

  Future<(bool, String)> cancelInvite(String inviteId) async {
    state = const AsyncValue.loading();
    final result = await _repo.cancelInvite(inviteId);
    if (result.success) {
      _ref.invalidate(staffInvitesProvider);
      state = const AsyncValue.data(null);
      return (true, result.message);
    }
    state = AsyncValue.error(
      ApiFailure(result.message,
          code: result.code, statusCode: result.statusCode),
      StackTrace.current,
    );
    return (false, result.message);
  }

  Future<(bool, String)> removeStaff(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repo.removeStaff(userId);
    if (result.success) {
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
      return (true, result.message);
    }
    state = AsyncValue.error(
      ApiFailure(result.message,
          code: result.code, statusCode: result.statusCode),
      StackTrace.current,
    );
    return (false, result.message);
  }
}

final staffActionsProvider =
    StateNotifierProvider<StaffActionsNotifier, AsyncValue<void>>((ref) {
  return StaffActionsNotifier(ref.read(staffRepositoryProvider), ref);
});
