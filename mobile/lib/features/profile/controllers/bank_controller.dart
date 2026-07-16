import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../data/models/bank_account_model.dart';
import '../../../data/repositories/bank_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// Repository tài khoản nhận tiền OWNER.
final bankRepositoryProvider =
    Provider<BankRepository>((ref) => BankRepository());

/// Trạng thái tài khoản nhận tiền hiện tại — `GET /users/me/bank`.
final bankStatusProvider = FutureProvider<BankStatusResult>((ref) async {
  final repo = ref.watch(bankRepositoryProvider);
  final result = await repo.getBank();
  if (result.success && result.data != null) return result.data!;
  throw ApiFailure(result.message,
      code: result.code, statusCode: result.statusCode);
});

/// Gửi/cập nhật tài khoản nhận tiền — `PUT /users/me/bank` → chờ ADMIN duyệt.
class BankActionsNotifier extends StateNotifier<AsyncValue<void>> {
  BankActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Trả `(true, message)` khi gửi thành công (đã chuyển sang chờ duyệt).
  Future<(bool, String)> submit(BankDetail detail) async {
    state = const AsyncValue.loading();
    final repo = _ref.read(bankRepositoryProvider);
    final result = await repo.updateBank(detail);
    if (result.success) {
      // Refetch trạng thái bank + đồng bộ profile (user.bankStatus) để cổng
      // tạo phòng + banner cập nhật ngay.
      _ref.invalidate(bankStatusProvider);
      await _ref.read(authProvider.notifier).refreshProfile();
      state = const AsyncValue.data(null);
      return (true, result.message);
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }
}

final bankActionsProvider =
    StateNotifierProvider<BankActionsNotifier, AsyncValue<void>>(
  (ref) => BankActionsNotifier(ref),
);
