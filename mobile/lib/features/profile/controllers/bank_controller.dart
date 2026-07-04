import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bank_account.dart';
import '../data/repositories/bank_repository.dart';

final bankRepositoryProvider =
    Provider<BankRepository>((ref) => BankRepository());

/// Trạng thái tài khoản nhận tiền OWNER (GET /users/me/bank).
/// Invalidate sau khi submit hoặc nhận FCM bank_approved/bank_rejected.
final bankStatusProvider = FutureProvider<BankStatusResult>((ref) async {
  final repo = ref.read(bankRepositoryProvider);
  final result = await repo.getMyBank();
  if (result.success && result.data != null) {
    return result.data!;
  }
  throw Exception(result.message);
});
