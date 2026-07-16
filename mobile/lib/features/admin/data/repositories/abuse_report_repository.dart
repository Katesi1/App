import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/abuse_report.dart';
import 'abuse_report_repository_impl.dart';

/// Real impl gọi backend Disputes (`/admin/disputes`). QA override bằng
/// `abuseReportRepositoryProvider.overrideWithValue(MockAbuseReportRepository())`.
final abuseReportRepositoryProvider = Provider<AbuseReportRepository>(
  (ref) => AbuseReportRepositoryImpl(),
);

abstract class AbuseReportRepository {
  Future<List<AbuseReport>> fetchAll();

  Future<AbuseReport?> fetchById(String id);

  Future<AbuseReport> investigate(String id, {required String adminName});

  Future<AbuseReport> dismiss(String id, {required String adminName});

  Future<AbuseReport> resolve(
    String id, {
    required String adminName,
    required String resolution,
    bool hideContent = false,
    bool banUser = false,
  });
}
