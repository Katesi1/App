import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/admin_bank_account.dart';
import '../data/repositories/admin_bank_repository.dart';

/// Filter cho queue duyệt tài khoản nhận tiền — map thẳng sang query `?status=`
/// của backend (§3.3): `pending` | `approved` | `rejected` | `all`.
enum BankQueueFilter { pending, approved, rejected, all }

extension BankQueueFilterApi on BankQueueFilter {
  String get apiValue => switch (this) {
        BankQueueFilter.pending => 'pending',
        BankQueueFilter.approved => 'approved',
        BankQueueFilter.rejected => 'rejected',
        BankQueueFilter.all => 'all',
      };

  String get label => switch (this) {
        BankQueueFilter.pending => 'Chờ duyệt',
        BankQueueFilter.approved => 'Đã duyệt',
        BankQueueFilter.rejected => 'Từ chối',
        BankQueueFilter.all => 'Tất cả',
      };
}

final adminBankRepositoryProvider =
    Provider<AdminBankRepository>((ref) => AdminBankRepository());

/// Filter state (UI). Đổi tab → refetch [bankQueueProvider].
final bankQueueFilterProvider =
    StateProvider<BankQueueFilter>((_) => BankQueueFilter.pending);

/// Queue theo tab đang chọn — 1 call `GET /admin/bank-accounts?status=…`.
/// `pendingCount` đi kèm mọi response nên badge luôn đúng dù đang ở tab nào.
final bankQueueProvider = FutureProvider<AdminBankQueueResult>((ref) async {
  final filter = ref.watch(bankQueueFilterProvider);
  final result = await ref
      .read(adminBankRepositoryProvider)
      .fetchQueue(status: filter.apiValue);
  if (result.success && result.data != null) {
    return result.data!;
  }
  throw Exception(result.message);
});

/// Danh sách tài khoản của tab hiện tại (view tiện lợi của [bankQueueProvider]).
final filteredBankAccountsProvider =
    Provider<AsyncValue<List<AdminBankAccount>>>((ref) {
  return ref.watch(bankQueueProvider).whenData((r) => r.items);
});

/// Số yêu cầu đang chờ duyệt (badge menu admin) — đọc từ `pendingCount`.
final pendingBankCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(bankQueueProvider).whenData((r) => r.pendingCount);
});

/// Actions notifier — approve / reject.
class AdminBankActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AdminBankActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> approve(String userId) async {
    state = const AsyncValue.loading();
    final result = await _ref.read(adminBankRepositoryProvider).approve(userId);
    if (result.success) {
      _ref.invalidate(bankQueueProvider);
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }

  Future<bool> reject(String userId, {required String reason}) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(adminBankRepositoryProvider)
        .reject(userId, reason: reason);
    if (result.success) {
      _ref.invalidate(bankQueueProvider);
      state = const AsyncValue.data(null);
      return true;
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return false;
  }
}

final adminBankActionsProvider =
    StateNotifierProvider<AdminBankActionsNotifier, AsyncValue<void>>(
  (ref) => AdminBankActionsNotifier(ref),
);
