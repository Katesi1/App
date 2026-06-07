import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/staff_permission.dart';
import '../data/repositories/staff_permission_repository.dart';

final staffPermissionRepositoryProvider =
    Provider<StaffPermissionRepository>((ref) => StaffPermissionRepository());

/// Quyền của 1 nhân viên SALE (`GET /permissions/:userId`).
final staffPermissionsProvider = FutureProvider.autoDispose
    .family<StaffPermissions, String>((ref, userId) async {
  final result =
      await ref.read(staffPermissionRepositoryProvider).getPermissions(userId);
  if (result.success) return result.data!;
  throw Exception(result.message);
});
