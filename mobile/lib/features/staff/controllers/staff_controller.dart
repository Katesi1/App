import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../data/models/staff_invite.dart';
import '../data/repositories/staff_repository.dart';

export '../data/repositories/staff_repository.dart'
    show AcceptInviteOutcome, AcceptInviteSuccess, AcceptInviteFailure;

final staffRepositoryProvider =
    Provider<StaffRepository>((ref) => StaffRepository());

/// Filter status for `staffInvitesProvider`. UI dropdown sets this value.
final staffInviteFilterProvider =
    StateProvider<StaffInviteStatus?>((ref) => null);

/// Invites created by OWNER. Re-fetched after each mutation via `invalidate`.
final staffInvitesProvider =
    FutureProvider.autoDispose<List<StaffInvite>>((ref) async {
  final repo = ref.read(staffRepositoryProvider);
  final filter = ref.watch(staffInviteFilterProvider);
  final result = await repo.listInvites(status: filter);
  if (result.success) return result.data ?? const [];
  throw Exception(result.message);
});

/// OWNER's current SALE staff list.
final staffListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.read(staffRepositoryProvider);
  final result = await repo.listStaff(isActive: true);
  if (result.success) return result.data ?? const [];
  throw Exception(result.message);
});

/// Mutations: invite/cancel/remove. Returns `(success, message)` for UI snackbar.
class StaffActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final StaffRepository _repo;
  final Ref _ref;

  /// Machine-readable `code` of the last failed action (e.g.
  /// `subscription.featureLocked`) so the UI can show the locked sheet instead
  /// of a plain snackbar. Reset on each action start.
  String? lastErrorCode;

  StaffActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<(bool, String)> invite(String email) async {
    state = const AsyncValue.loading();
    lastErrorCode = null;
    final result = await _repo.createInvite(email);
    if (result.success) {
      _ref.invalidate(staffInvitesProvider);
      state = const AsyncValue.data(null);
      return (true, result.message);
    }
    lastErrorCode = result.code;
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }

  Future<(bool, String)> cancelInvite(String inviteId) async {
    state = const AsyncValue.loading();
    final result = await _repo.cancelInvite(inviteId);
    if (result.success) {
      _ref.invalidate(staffInvitesProvider);
      state = const AsyncValue.data(null);
      return (true, result.message);
    }
    state = AsyncValue.error(result.message, StackTrace.current);
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
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }
}

final staffActionsProvider =
    StateNotifierProvider<StaffActionsNotifier, AsyncValue<void>>((ref) {
  return StaffActionsNotifier(ref.read(staffRepositoryProvider), ref);
});
