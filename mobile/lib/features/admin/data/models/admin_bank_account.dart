/// Một dòng trong queue duyệt tài khoản nhận tiền OWNER (phía ADMIN).
///
/// Nguồn: `GET /admin/bank-accounts` → `data.items[]` (xem API_SPEC §3.3).
/// Tái sử dụng [BankInfo] + [BankApprovalStatus] từ feature `profile` — admin
/// chỉ REVIEW dữ liệu do luồng "Tài khoản nhận tiền" của OWNER tạo ra, không
/// sở hữu model riêng (cùng lý do `admin/kyc` import model của `verify`, xem
/// CLAUDE.md §10 — ngoại lệ cross-feature cho admin review).
library;

import '../../../profile/data/models/bank_account.dart';

class AdminBankAccount {
  final String id; // userId của OWNER gửi yêu cầu
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final BankApprovalStatus status;
  final BankInfo? current; // tài khoản đã duyệt (đang dùng cho VietQR)
  final BankInfo? pending; // yêu cầu đang chờ — != null CHỈ khi status=pending
  final String? rejectReason; // != null CHỈ khi status=rejected
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const AdminBankAccount({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    required this.status,
    this.current,
    this.pending,
    this.rejectReason,
    this.submittedAt,
    this.reviewedAt,
  });

  /// Tài khoản để hiển thị nổi bật: ưu tiên `pending` (cái cần duyệt) rồi tới
  /// `current` (cái đang dùng, cho các tab đã xử lý).
  BankInfo? get displayInfo => pending ?? current;

  bool get isPending => status == BankApprovalStatus.pending;
  bool get isApproved => status == BankApprovalStatus.approved;
  bool get isRejected => status == BankApprovalStatus.rejected;

  factory AdminBankAccount.fromJson(Map<String, dynamic> json) {
    BankInfo? parse(dynamic v) =>
        v is Map<String, dynamic> ? BankInfo.fromJson(v) : null;
    DateTime? date(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return AdminBankAccount(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      status: bankApprovalStatusFromApi(json['status'] as String?),
      current: parse(json['current']),
      pending: parse(json['pending']),
      rejectReason: json['rejectReason'] as String?,
      submittedAt: date(json['submittedAt']),
      reviewedAt: date(json['reviewedAt']),
    );
  }
}

/// Kết quả `GET /admin/bank-accounts` — danh sách + đếm chờ duyệt (badge).
class AdminBankQueueResult {
  final List<AdminBankAccount> items;
  final int pendingCount; // dùng cho badge menu admin (mọi filter đều trả về)
  final int total;

  const AdminBankQueueResult({
    required this.items,
    required this.pendingCount,
    required this.total,
  });
}
