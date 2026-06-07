import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/moderation_models.dart';
import '../data/repositories/moderation_repository.dart';

final moderationRepositoryProvider =
    Provider<ModerationRepository>((ref) => ModerationRepository());

/// Bộ lọc trạng thái cho danh sách khiếu nại (null = tất cả).
final disputeStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Danh sách khiếu nại (`GET /admin/disputes`), lọc theo `disputeStatusFilterProvider`.
final disputesProvider =
    FutureProvider.autoDispose<List<DisputeModel>>((ref) async {
  final status = ref.watch(disputeStatusFilterProvider);
  final result =
      await ref.read(moderationRepositoryProvider).getDisputes(status: status);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// Nhật ký kiểm duyệt (`GET /admin/audit-log`).
final auditLogProvider =
    FutureProvider.autoDispose<List<AuditEntry>>((ref) async {
  final result = await ref.read(moderationRepositoryProvider).getAuditLog();
  if (result.success) return result.data!;
  throw Exception(result.message);
});
