import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/audit_log_model.dart';
import '../../../data/repositories/admin_audit_repository.dart';

final auditRepositoryProvider =
    Provider<AdminAuditRepository>((ref) => AdminAuditRepository());

/// Tham số lọc cho danh sách audit-log. Dùng record cho value-equality làm
/// key của `FutureProvider.family` (đổi filter → provider mới fetch).
typedef AuditLogQuery = ({String? targetType, String? search, int page});

/// Lấy 1 trang nhật ký audit theo filter. autoDispose để giải phóng khi rời
/// màn; family nhận filter (targetType + search + page).
final auditLogProvider =
    FutureProvider.family.autoDispose<AuditLogPage, AuditLogQuery>(
  (ref, query) async {
    final repo = ref.read(auditRepositoryProvider);
    final result = await repo.getAuditLog(
      targetType: query.targetType,
      search: query.search,
      page: query.page,
    );
    if (result.success && result.data != null) {
      return result.data!;
    }
    throw Exception(result.message);
  },
);
