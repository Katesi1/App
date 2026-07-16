import 'package:equatable/equatable.dart';

/// Chi tiết 1 tài khoản ngân hàng nhận tiền (current hoặc pending).
/// BE §3.3 — `{ bankBin, bankName?, bankAccountNumber, bankAccountName }`.
class BankDetail extends Equatable {
  final String bankBin;
  final String? bankName;
  final String bankAccountNumber;
  final String bankAccountName;

  const BankDetail({
    required this.bankBin,
    this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
  });

  factory BankDetail.fromJson(Map<String, dynamic> json) => BankDetail(
        bankBin: json['bankBin']?.toString() ?? '',
        bankName: json['bankName']?.toString(),
        bankAccountNumber: json['bankAccountNumber']?.toString() ?? '',
        bankAccountName: json['bankAccountName']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'bankBin': bankBin,
        if (bankName != null && bankName!.isNotEmpty) 'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'bankAccountName': bankAccountName,
      };

  @override
  List<Object?> get props =>
      [bankBin, bankName, bankAccountNumber, bankAccountName];
}

/// Kết quả `GET`/`PUT /users/me/bank` (BE §3.3).
/// - [current]: tài khoản đã duyệt đang dùng cho VietQR (null nếu chưa từng).
/// - [pending]: giá trị đang chờ duyệt (chỉ khi `status='pending'`).
/// - [rejectReason]: chỉ khi `status='rejected'`.
class BankStatusResult extends Equatable {
  final String status; // none | pending | approved | rejected
  final BankDetail? current;
  final BankDetail? pending;
  final String? rejectReason;
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

  bool get isNone => status == 'none';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  static BankDetail? _detail(dynamic raw) =>
      raw is Map<String, dynamic> ? BankDetail.fromJson(raw) : null;

  static DateTime? _date(dynamic raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  factory BankStatusResult.fromJson(Map<String, dynamic> json) =>
      BankStatusResult(
        status: json['status']?.toString() ?? 'none',
        current: _detail(json['current']),
        pending: _detail(json['pending']),
        rejectReason: json['rejectReason']?.toString(),
        submittedAt: _date(json['submittedAt']),
        reviewedAt: _date(json['reviewedAt']),
      );

  @override
  List<Object?> get props =>
      [status, current, pending, rejectReason, submittedAt, reviewedAt];
}
