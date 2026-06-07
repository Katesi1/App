import 'package:equatable/equatable.dart';

import 'kyc_submission.dart';

/// Response paginated của `GET /admin/kyc/queue?filter=0|1|2|3` (v1.11).
class KycQueuePage extends Equatable {
  final int filter;
  final int pendingCount;
  final int total;
  final int page;
  final int pageSize;
  final List<KYCSubmission> items;

  const KycQueuePage({
    required this.filter,
    required this.pendingCount,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  @override
  List<Object?> get props =>
      [filter, pendingCount, total, page, pageSize, items];
}
