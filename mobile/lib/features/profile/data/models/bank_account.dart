/// Tài khoản nhận tiền của OWNER + trạng thái duyệt bởi admin.
/// Endpoint: GET/PUT `/users/me/bank` (xem API_SPEC — phần bank).
///
/// Hand-written (không codegen) như các model feature-local khác
/// (vd `payment_session.dart`) vì shape đơn giản và có field lồng nhau.
library;

enum BankApprovalStatus { none, pending, approved, rejected }

BankApprovalStatus bankApprovalStatusFromApi(String? s) => switch (s) {
      'pending' => BankApprovalStatus.pending,
      'approved' => BankApprovalStatus.approved,
      'rejected' => BankApprovalStatus.rejected,
      _ => BankApprovalStatus.none,
    };

/// Thông tin 1 tài khoản ngân hàng (dùng cho `current` đã duyệt và `pending`
/// đang chờ, cũng là body gửi lên khi submit).
class BankInfo {
  final String bankBin; // NAPAS 6 số
  final String? bankName; // optional
  final String bankAccountNumber; // 6–20 số
  final String bankAccountName;

  const BankInfo({
    required this.bankBin,
    this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) => BankInfo(
        bankBin: (json['bankBin'] ?? '') as String,
        bankName: json['bankName'] as String?,
        bankAccountNumber: (json['bankAccountNumber'] ?? '') as String,
        bankAccountName: (json['bankAccountName'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'bankBin': bankBin,
        if (bankName != null && bankName!.isNotEmpty) 'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'bankAccountName': bankAccountName,
      };
}

/// Kết quả GET/PUT `/users/me/bank`.
class BankStatusResult {
  final BankApprovalStatus status;
  final BankInfo? current; // tài khoản đang dùng (đã duyệt)
  final BankInfo? pending; // != null CHỈ khi status = pending
  final String? rejectReason; // != null CHỈ khi status = rejected
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const BankStatusResult({
    required this.status,
    this.current,
    this.pending,
    this.rejectReason,
    this.submittedAt,
    this.reviewedAt,
  });

  factory BankStatusResult.fromJson(Map<String, dynamic> json) {
    BankInfo? parse(dynamic v) =>
        v is Map<String, dynamic> ? BankInfo.fromJson(v) : null;
    DateTime? date(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return BankStatusResult(
      status: bankApprovalStatusFromApi(json['status'] as String?),
      current: parse(json['current']),
      pending: parse(json['pending']),
      rejectReason: json['rejectReason'] as String?,
      submittedAt: date(json['submittedAt']),
      reviewedAt: date(json['reviewedAt']),
    );
  }

  /// Tài khoản để hiển thị: ưu tiên `pending` (đang chờ) rồi tới `current`.
  BankInfo? get displayInfo => pending ?? current;

  bool get isNone => status == BankApprovalStatus.none;
  bool get isPending => status == BankApprovalStatus.pending;
  bool get isApproved => status == BankApprovalStatus.approved;
  bool get isRejected => status == BankApprovalStatus.rejected;
}
