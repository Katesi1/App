import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../verify/data/models/verify_enums.dart';
import '../data/models/kyc_queue_page.dart';
import '../data/models/kyc_submission.dart';
import '../data/repositories/admin_kyc_repository.dart';

export '../data/repositories/admin_kyc_repository.dart'
    show KYCQueueFilter, KYCQueueFilterX;

/// State của filter (UI controlled).
final kycQueueFilterProvider =
    StateProvider<KYCQueueFilter>((_) => KYCQueueFilter.pending);

/// Queue theo tab — một request `GET /admin/kyc/queue?filter=0|1|2|3`.
final kycQueueProvider = FutureProvider.family<KycQueuePage, KYCQueueFilter>(
  (ref, filter) => ref.watch(adminKYCRepositoryProvider).fetchQueue(filter),
);

/// Items đã sort theo quy tắc từng tab.
final sortedKycSubmissionsProvider =
    Provider.family<AsyncValue<List<KYCSubmission>>, KYCQueueFilter>(
        (ref, filter) {
  final queue = ref.watch(kycQueueProvider(filter));
  return queue.whenData((page) => _sortSubmissions(page.items, filter));
});

List<KYCSubmission> _sortSubmissions(
  List<KYCSubmission> items,
  KYCQueueFilter filter,
) {
  final sorted = List<KYCSubmission>.from(items);
  if (filter == KYCQueueFilter.pending) {
    sorted.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      return a.submittedAt.compareTo(b.submittedAt);
    });
  } else {
    sorted.sort((a, b) {
      final ah = a.handledAt ?? a.submittedAt;
      final bh = b.handledAt ?? b.submittedAt;
      return bh.compareTo(ah);
    });
  }
  return sorted;
}

/// Badge sidebar — `pendingCount` từ BE, không đếm client-side.
final pendingKycCountProvider = Provider<AsyncValue<int>>((ref) {
  final queue = ref.watch(kycQueueProvider(KYCQueueFilter.pending));
  return queue.whenData((page) => page.pendingCount);
});

/// Detail của 1 submission.
final kycSubmissionProvider =
    FutureProvider.family<KYCSubmission?, String>((ref, id) {
  return ref.watch(adminKYCRepositoryProvider).fetchById(id);
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
