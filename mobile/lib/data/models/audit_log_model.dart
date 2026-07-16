import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Một dòng nhật ký audit (moderation / admin action) trả từ
/// `GET /admin/audit-log`. Parse phòng thủ — KHÔNG throw trong [fromJson]
/// (BE có thể thiếu field, trả null, hoặc kiểu khác kỳ vọng).
@immutable
class AuditLogEntry {
  final String id;
  final String actorId;
  final int? actorRole;

  /// Thông tin actor kèm theo (`{ id, name, email, role }`). Có thể null.
  final Map<String, dynamic>? actor;

  /// Slug hành động, vd `user.ban`, `kyc.approve`.
  final String action;

  /// Loại đối tượng bị tác động: `user|property|booking|dispute|subscription
  /// |review|kyc`.
  final String targetType;
  final String targetId;

  /// Nhãn hiển thị của đối tượng (vd email người bị khóa). Có thể rỗng.
  final String targetLabel;

  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  const AuditLogEntry({
    required this.id,
    required this.actorId,
    this.actorRole,
    this.actor,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final rawActor = json['actor'];
    final rawMeta = json['metadata'];
    return AuditLogEntry(
      id: json['id']?.toString() ?? '',
      actorId: json['actorId']?.toString() ?? '',
      actorRole: (json['actorRole'] as num?)?.toInt(),
      actor: rawActor is Map
          ? Map<String, dynamic>.from(rawActor)
          : null,
      action: json['action']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      targetLabel: json['targetLabel']?.toString() ?? '',
      metadata: rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : null,
      ipAddress: json['ipAddress']?.toString(),
      userAgent: json['userAgent']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')
          ?.toLocal(),
    );
  }

  /// Tên người thực hiện — ưu tiên `actor.name`, fallback email, cuối cùng là
  /// 'Hệ thống' (khi hành động do backend tự sinh).
  String get actorName {
    final name = actor?['name']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final email = actor?['email']?.toString();
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'Hệ thống';
  }

  /// Lý do đính kèm trong metadata (nếu có) — hiển thị dòng phụ.
  String? get reason {
    final r = metadata?['reason']?.toString();
    if (r == null || r.trim().isEmpty) {
      return null;
    }
    return r.trim();
  }

  /// Nhóm hành động, suy ra từ prefix của slug `action` (`user.ban` → `user`),
  /// fallback về `targetType` nếu slug không có dấu chấm.
  String get category {
    final dot = action.indexOf('.');
    if (dot > 0) {
      return action.substring(0, dot);
    }
    return targetType.isNotEmpty ? targetType : 'other';
  }

  /// Nhãn tiếng Việt của hành động. Map đầy đủ 27 slug đã xác nhận với BE;
  /// slug lạ → hiển thị nguyên slug để không mất thông tin.
  String get actionLabel => _actionLabels[action] ?? action;

  /// Nhãn tiếng Việt ngắn của nhóm.
  String get categoryLabel => _categoryLabels[category] ?? 'Khác';

  /// Màu đại diện cho nhóm (dùng cho badge). Trả về hằng số [AppColors] —
  /// KHÔNG hardcode `Color(0x...)` ở view.
  Color get categoryColor => _categoryColors[category] ?? AppColors.slate500;

  static const Map<String, String> _categoryLabels = {
    'user': 'Người dùng',
    'property': 'Cơ sở',
    'subscription': 'Gói',
    'review': 'Đánh giá',
    'kyc': 'KYC',
    'dispute': 'Khiếu nại',
    'booking': 'Booking',
    'payment': 'Thanh toán',
  };

  static const Map<String, Color> _categoryColors = {
    'user': AppColors.coral500,
    'property': AppColors.jade500,
    'subscription': AppColors.gold700,
    'review': AppColors.warning,
    'kyc': AppColors.jade300,
    'dispute': AppColors.error,
    'booking': AppColors.success,
    'payment': AppColors.slate600,
  };

  static const Map<String, String> _actionLabels = {
    'user.ban': 'Khóa người dùng',
    'user.unban': 'Mở khóa người dùng',
    'user.revoke_sessions': 'Thu hồi phiên đăng nhập',
    'user.reset_password': 'Đặt lại mật khẩu',
    'user.change_role': 'Đổi vai trò',
    'user.delete': 'Xóa người dùng',
    'user.kyc_bypass_toggle': 'Bật/tắt bỏ qua KYC',
    'user.bank_approve': 'Duyệt tài khoản ngân hàng',
    'user.bank_reject': 'Từ chối tài khoản ngân hàng',
    'property.approve': 'Duyệt cơ sở',
    'property.reject': 'Từ chối cơ sở',
    'property.suspend': 'Tạm ẩn cơ sở',
    'subscription.trial_grant': 'Cấp dùng thử',
    'subscription.trial_revoke': 'Thu hồi dùng thử',
    'subscription.set_price': 'Đặt giá gói',
    'subscription.mark_paid': 'Xác nhận thanh toán',
    'subscription.freeze': 'Tạm dừng gói',
    'subscription.unfreeze': 'Kích hoạt lại gói',
    'review.hide': 'Ẩn đánh giá',
    'review.restore': 'Khôi phục đánh giá',
    'kyc.approve': 'Duyệt KYC',
    'kyc.reject': 'Từ chối KYC',
    'dispute.investigate': 'Điều tra khiếu nại',
    'dispute.resolve': 'Giải quyết khiếu nại',
    'dispute.reject': 'Từ chối khiếu nại',
    'booking.mark_paid': 'Xác nhận thanh toán booking',
    'payment.receiving_bank_update': 'Cập nhật tài khoản nhận tiền',
  };
}

/// Một trang kết quả audit-log (listing Shape A: `{ items, total, page,
/// limit, totalPages }`).
@immutable
class AuditLogPage {
  final List<AuditLogEntry> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AuditLogPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory AuditLogPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsed = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => AuditLogEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AuditLogEntry>[];
    return AuditLogPage(
      items: parsed,
      total: (json['total'] as num?)?.toInt() ?? parsed.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
