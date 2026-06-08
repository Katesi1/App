import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../verify/data/models/verify_enums.dart';
import '../models/kyc_submission.dart';
import 'admin_kyc_repository_impl.dart';

final adminKYCRepositoryProvider = Provider<AdminKycRepository>(
  (ref) => AdminKycRepositoryImpl(),
);

/// Result of `GET /admin/kyc/queue?filter=…` — single endpoint (API v1.11).
///
/// Carries the server-filtered [items] plus [pendingCount] (the badge counter,
/// always the number of "chờ duyệt" submissions regardless of the active tab).
/// Replaces the old 3× parallel `?status=` fetch.
class KycQueueResult {
  final List<KYCSubmission> items;
  final int pendingCount;
  final int total;

  const KycQueueResult({
    required this.items,
    required this.pendingCount,
    required this.total,
  });
}

abstract class AdminKycRepository {
  /// Fetch the admin KYC queue for a given tab.
  ///
  /// [filter]: `0`=Tất cả, `1`=Chờ duyệt (default), `2`=Đã duyệt, `3`=Từ chối.
  /// Backend gathers DB statuses into these tabs and returns `pendingCount`
  /// in the same response — no separate badge call needed.
  Future<KycQueueResult> fetchQueue({int filter = 1});

  Future<KYCSubmission?> fetchById(String id);

  Future<KYCSubmission> approve(String id, {required String adminName});

  Future<KYCSubmission> reject(
    String id, {
    required String adminName,
    required String reason,
    required List<RejectableItem> items,
  });
}
