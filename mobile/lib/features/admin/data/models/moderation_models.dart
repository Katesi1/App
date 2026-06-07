/// Models cho 2 màn moderation của ADMIN: Disputes (báo cáo/khiếu nại) và
/// Audit Log (nhật ký kiểm duyệt). Shape theo `docs/API_SPEC_FULL.md` §13, §14.
library;

/// Một khiếu nại/tranh chấp (`GET /admin/disputes`).
class DisputeModel {
  final String id;
  final String type; // refund_request | service_quality | damage_claim | ...
  final String status; // pending | investigating | resolved | rejected
  final String subject;
  final String description;
  final double? amount;
  final String? openerType; // owner | sale | customer | admin
  final String? bookingId;
  final String? propertyName;
  final String? customerName;
  final String? ownerName;
  final DateTime? createdAt;

  const DisputeModel({
    required this.id,
    required this.type,
    required this.status,
    required this.subject,
    required this.description,
    this.amount,
    this.openerType,
    this.bookingId,
    this.propertyName,
    this.customerName,
    this.ownerName,
    this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    String? nestedName(dynamic v) =>
        v is Map ? (v['name'] ?? v['title']) as String? : null;
    return DisputeModel(
      id: (json['id'] ?? '') as String,
      type: (json['type'] ?? 'other') as String,
      status: (json['status'] ?? 'pending') as String,
      subject: (json['subject'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble(),
      openerType: json['openerType'] as String?,
      bookingId: json['bookingId'] as String?,
      propertyName:
          nestedName(json['property']) ?? json['propertyName'] as String?,
      customerName:
          nestedName(json['customer']) ?? json['customerName'] as String?,
      ownerName: nestedName(json['owner']) ?? json['ownerName'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  /// Nhãn loại tiếng Việt.
  String get typeLabel => switch (type) {
        'refund_request' => 'Yêu cầu hoàn tiền',
        'service_quality' => 'Chất lượng dịch vụ',
        'damage_claim' => 'Đòi bồi thường hư hỏng',
        'no_show' => 'Khách không đến',
        'overbooking' => 'Trùng booking',
        _ => 'Khác',
      };

  /// Nhãn trạng thái tiếng Việt.
  String get statusLabel => switch (status) {
        'pending' => 'Chờ xử lý',
        'investigating' => 'Đang điều tra',
        'resolved' => 'Đã giải quyết',
        'rejected' => 'Đã từ chối',
        _ => status,
      };

  bool get isActive => status == 'pending' || status == 'investigating';
}

/// Một dòng nhật ký kiểm duyệt (`GET /admin/audit-log`).
class AuditEntry {
  final String id;
  final String action; // slug, e.g. "user.ban"
  final String? actorName;
  final String targetType; // user | property | booking | dispute | ...
  final String? targetId;
  final String? targetLabel;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const AuditEntry({
    required this.id,
    required this.action,
    this.actorName,
    required this.targetType,
    this.targetId,
    this.targetLabel,
    this.metadata,
    this.createdAt,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'];
    return AuditEntry(
      id: (json['id'] ?? '') as String,
      action: (json['action'] ?? '') as String,
      actorName: actor is Map ? actor['name'] as String? : null,
      targetType: (json['targetType'] ?? '') as String,
      targetId: json['targetId'] as String?,
      targetLabel: json['targetLabel'] as String?,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: _date(json['createdAt']),
    );
  }

  /// Mô tả hành động tiếng Việt từ action slug.
  String get actionLabel => switch (action) {
        'user.ban' => 'Khoá người dùng',
        'user.unban' => 'Mở khoá người dùng',
        'user.revoke_sessions' => 'Thu hồi phiên đăng nhập',
        'user.reset_password' => 'Đặt lại mật khẩu',
        'user.change_role' => 'Đổi vai trò',
        'user.delete' => 'Xoá người dùng',
        'user.kyc_bypass_toggle' => 'Bật/tắt bỏ qua KYC',
        'property.approve' => 'Duyệt cơ sở',
        'property.reject' => 'Từ chối cơ sở',
        'property.suspend' => 'Tạm ngưng cơ sở',
        'subscription.trial_grant' => 'Cấp dùng thử',
        'subscription.trial_revoke' => 'Thu hồi dùng thử',
        'subscription.set_price' => 'Đặt giá gói',
        'subscription.mark_paid' => 'Xác nhận thanh toán gói',
        'subscription.freeze' => 'Đóng băng gói',
        'subscription.unfreeze' => 'Mở đóng băng gói',
        'review.hide' => 'Ẩn đánh giá',
        'review.restore' => 'Khôi phục đánh giá',
        'kyc.approve' => 'Duyệt KYC',
        'kyc.reject' => 'Từ chối KYC',
        'dispute.investigate' => 'Điều tra khiếu nại',
        'dispute.resolve' => 'Giải quyết khiếu nại',
        'dispute.reject' => 'Từ chối khiếu nại',
        'booking.mark_paid' => 'Xác nhận thu tiền booking',
        _ => action,
      };

  /// Lý do (nếu metadata có `reason`).
  String? get reason => metadata?['reason'] as String?;
}

DateTime? _date(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
