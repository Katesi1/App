import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../verify/data/models/verify_enums.dart';
import '../models/kyc_submission.dart';
import 'admin_kyc_repository_impl.dart';

final adminKYCRepositoryProvider = Provider<AdminKycRepository>(
  (ref) => AdminKycRepositoryImpl(),
);

abstract class AdminKycRepository {
  Future<List<KYCSubmission>> fetchAll();

  Future<KYCSubmission?> fetchById(String id);

  Future<KYCSubmission> approve(String id, {required String adminName});

  Future<KYCSubmission> reject(
    String id, {
    required String adminName,
    required String reason,
    required List<RejectableItem> items,
  });
}
