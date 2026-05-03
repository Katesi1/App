import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../verify/data/models/verify_enums.dart';
import '../data/models/kyc_submission.dart';
import '../data/repositories/admin_kyc_repository.dart';

/// Filter cho admin KYC list.
enum KYCQueueFilter { pending, all, approved, rejected }

/// State của filter (UI controlled).
final kycQueueFilterProvider =
    StateProvider<KYCQueueFilter>((_) => KYCQueueFilter.pending);

/// Toàn bộ submissions (pre-filter).
final kycSubmissionsProvider = FutureProvider<List<KYCSubmission>>(
  (ref) => ref.read(adminKYCRepositoryProvider).fetchAll(),
);

/// Submissions sau khi áp filter — sort overdue/oldest pending lên đầu.
final filteredKycSubmissionsProvider =
    Provider<AsyncValue<List<KYCSubmission>>>((ref) {
  final filter = ref.watch(kycQueueFilterProvider);
  final all = ref.watch(kycSubmissionsProvider);
  return all.whenData((list) {
    final filtered = switch (filter) {
      KYCQueueFilter.pending => list
          .where((s) => s.status == VerifyStatus.awaitingApproval)
          .toList(),
      KYCQueueFilter.approved =>
        list.where((s) => s.status == VerifyStatus.approved).toList(),
      KYCQueueFilter.rejected =>
        list.where((s) => s.status == VerifyStatus.rejected).toList(),
      KYCQueueFilter.all => List<KYCSubmission>.from(list),
    };

    // Pending: overdue lên đầu, sau đó oldest first (FIFO).
    // Resolved (approved/rejected): newest first.
    if (filter == KYCQueueFilter.pending) {
      filtered.sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        return a.submittedAt.compareTo(b.submittedAt);
      });
    } else {
      filtered.sort((a, b) {
        final ah = a.handledAt ?? a.submittedAt;
        final bh = b.handledAt ?? b.submittedAt;
        return bh.compareTo(ah);
      });
    }
    return filtered;
  });
});

/// Số submission pending (cho badge counter trên admin home).
final pendingKycCountProvider = Provider<AsyncValue<int>>((ref) {
  final all = ref.watch(kycSubmissionsProvider);
  return all.whenData(
    (list) => list.where((s) => s.isPending).length,
  );
});

/// Detail của 1 submission.
final kycSubmissionProvider =
    FutureProvider.family<KYCSubmission?, String>((ref, id) {
  return ref.read(adminKYCRepositoryProvider).fetchById(id);
});

/// Actions notifier — approve / reject mutations.
class KYCApprovalActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  KYCApprovalActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> approve(String id, {required String adminName}) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(adminKYCRepositoryProvider)
          .approve(id, adminName: adminName);
      _ref.invalidate(kycSubmissionsProvider);
      _ref.invalidate(kycSubmissionProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reject(
    String id, {
    required String adminName,
    required String reason,
    required List<RejectableItem> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(adminKYCRepositoryProvider).reject(
            id,
            adminName: adminName,
            reason: reason,
            items: items,
          );
      _ref.invalidate(kycSubmissionsProvider);
      _ref.invalidate(kycSubmissionProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final kycApprovalActionsProvider =
    StateNotifierProvider<KYCApprovalActionsNotifier, AsyncValue<void>>(
  (ref) => KYCApprovalActionsNotifier(ref),
);
