import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account_models.dart';
import '../data/repositories/account_repository.dart';

final accountRepositoryProvider =
    Provider<AccountRepository>((ref) => AccountRepository());

/// Danh sách ticket hỗ trợ của user (`GET /support/tickets`).
final ticketListProvider =
    FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final result = await ref.read(accountRepositoryProvider).getTickets();
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// Chi tiết 1 ticket + messages (`GET /support/tickets/:id`).
final ticketDetailProvider =
    FutureProvider.autoDispose.family<SupportTicket, String>((ref, id) async {
  final result = await ref.read(accountRepositoryProvider).getTicket(id);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// Lịch sử yêu cầu xuất dữ liệu (`GET /users/me/data-export`).
final dataExportsProvider =
    FutureProvider.autoDispose<List<DataExportRequest>>((ref) async {
  final result = await ref.read(accountRepositoryProvider).getDataExports();
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// Quyền đồng ý (`GET /users/me/consents`).
final consentsProvider =
    FutureProvider.autoDispose<ConsentSettings>((ref) async {
  final result = await ref.read(accountRepositoryProvider).getConsents();
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// Tuỳ chọn thông báo (`GET /users/me/notification-preferences`).
final notificationPrefsProvider =
    FutureProvider.autoDispose<NotificationPrefs>((ref) async {
  final result =
      await ref.read(accountRepositoryProvider).getNotificationPrefs();
  if (result.success) return result.data!;
  throw Exception(result.message);
});
