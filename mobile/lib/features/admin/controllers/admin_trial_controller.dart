import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/trial_snapshot.dart';
import '../data/repositories/admin_trial_repository.dart';
import '../data/repositories/admin_trial_repository_impl.dart';

// Override provider này với real impl khi startup
final adminTrialRepositoryProvider =
    Provider<AdminTrialRepository>((ref) => AdminTrialRepositoryImpl());

/// Load subscription snapshot cho một user cụ thể.
final trialSnapshotProvider =
    FutureProvider.family<TrialSnapshot, String>((ref, userId) async {
  final repo = ref.watch(adminTrialRepositoryProvider);
  return repo.fetchSubscription(userId);
});

// ─── Grant / Revoke Notifier ─────────────────────────────────────────────────

class AdminTrialNotifier extends StateNotifier<AsyncValue<void>> {
  AdminTrialNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final AdminTrialRepository _repo;
  final Ref _ref;

  Future<bool> grant({
    required String userId,
    required int days,
    String? planId,
    String? cycle,
    int? rooms,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.grantTrial(
        userId: userId,
        days: days,
        planId: planId,
        cycle: cycle,
        rooms: rooms,
        reason: reason,
      );
      _ref.invalidate(trialSnapshotProvider(userId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> revoke({
    required String userId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.revokeTrial(userId: userId, reason: reason);
      _ref.invalidate(trialSnapshotProvider(userId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final adminTrialNotifierProvider =
    StateNotifierProvider.autoDispose<AdminTrialNotifier, AsyncValue<void>>(
  (ref) => AdminTrialNotifier(ref.watch(adminTrialRepositoryProvider), ref),
);
