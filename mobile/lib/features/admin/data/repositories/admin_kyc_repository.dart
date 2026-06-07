import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../verify/data/models/verify_enums.dart';
import '../models/kyc_queue_page.dart';
import '../models/kyc_submission.dart';
import 'admin_kyc_repository_impl.dart';

final adminKYCRepositoryProvider = Provider<AdminKycRepository>(
  (ref) => AdminKycRepositoryImpl(),
);

/// Tab filter map sang query `filter` của BE (0–3).
enum KYCQueueFilter { pending, all, approved, rejected }

extension KYCQueueFilterX on KYCQueueFilter {
  int get apiFilter => switch (this) {
        KYCQueueFilter.all => 0,
        KYCQueueFilter.pending => 1,
        KYCQueueFilter.approved => 2,
        KYCQueueFilter.rejected => 3,
      };
}

abstract class AdminKycRepository {
  Future<KycQueuePage> fetchQueue(
    KYCQueueFilter filter, {
    int page = 1,
    int pageSize = 20,
  });

  Future<KYCSubmission?> fetchById(String id);

  Future<KYCSubmission> approve(String id, {required String adminName});

  Future<KYCSubmission> reject(
    String id, {
    required String adminName,
    required String reason,
    required List<RejectableItem> items,
  });
}
