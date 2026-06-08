import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../verify/data/models/verify_enums.dart';
import '../data/models/kyc_submission.dart';
import '../data/repositories/admin_kyc_repository.dart';

/// Filter for the admin KYC list. Maps to the backend `?filter=` query param
/// (API v1.11): `0`=all, `1`=pending, `2`=approved, `3`=rejected.
enum KYCQueueFilter { pending, all, approved, rejected }

extension KYCQueueFilterApi on KYCQueueFilter {
  /// Backend `filter` query value (see §9 — admin KYC queue).
  int get apiValue => switch (this) {
        KYCQueueFilter.all => 0,
        KYCQueueFilter.pending => 1,
        KYCQueueFilter.approved => 2,
        KYCQueueFilter.rejected => 3,
      };
}

/// Filter state (UI-controlled). Changing it re-fetches [kycQueueProvider].
final kycQueueFilterProvider =
    StateProvider<KYCQueueFilter>((_) => KYCQueueFilter.pending);

/// Queue for the active tab — single backend call `GET /queue?filter=…`.
/// Items come pre-filtered by the server; we only sort them client-side.
final kycQueueProvider = FutureProvider<KycQueueResult>((ref) async {
  final filter = ref.watch(kycQueueFilterProvider);
  final result = await ref
      .read(adminKYCRepositoryProvider)
      .fetchQueue(filter: filter.apiValue);

  final items = List<KYCSubmission>.from(result.items);
  // Pending: overdue first, then oldest first (FIFO).
  // Resolved (approved/rejected/all): newest first.
  if (filter == KYCQueueFilter.pending) {
    items.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      return a.submittedAt.compareTo(b.submittedAt);
    });
  } else {
    items.sort((a, b) {
      final ah = a.handledAt ?? a.submittedAt;
      final bh = b.handledAt ?? b.submittedAt;
      return bh.compareTo(ah);
    });
  }
  return KycQueueResult(
    items: items,
    pendingCount: result.pendingCount,
    total: result.total,
  );
});

/// Submissions for the active tab (sorted) — convenience view of [kycQueueProvider].
final filteredKycSubmissionsProvider =
    Provider<AsyncValue<List<KYCSubmission>>>((ref) {
  return ref.watch(kycQueueProvider).whenData((r) => r.items);
});

/// Number of pending submissions (badge counter) — read straight from the
/// queue response's `pendingCount`; no separate `/count-pending` call.
final pendingKycCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(kycQueueProvider).whenData((r) => r.pendingCount);
});

/// Detail of a single submission.
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
      _ref.invalidate(kycQueueProvider);
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
      _ref.invalidate(kycQueueProvider);
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
