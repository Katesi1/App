import 'package:flutter/material.dart';

/// 4 hành động CRUD trên mỗi module (khớp field backend
/// `canCreate/canRead/canUpdate/canDelete` — BE §12).
enum PermissionAction {
  read('canRead', 'Xem'),
  create('canCreate', 'Thêm'),
  update('canUpdate', 'Sửa'),
  delete('canDelete', 'Xoá');

  const PermissionAction(this.field, this.label);

  /// Key JSON gửi/nhận với backend.
  final String field;

  /// Nhãn tiếng Việt hiển thị trên toggle.
  final String label;
}

/// Nhóm phạm vi module (BE §26.2). `admin` = quyền cấp hệ thống dành cho SALE
/// hệ thống (default all false — phải cấp tường minh). `owner` = quyền theo
/// từng chủ, SALE hệ thống thường không cần nhưng vẫn lưu được.
enum PermissionScope { admin, owner }

/// Quyền của 1 user trên 1 module. Dùng cho cả parse (`GET /permissions/:id`)
/// lẫn gửi lưu (`PUT /permissions/:id`).
@immutable
class UserPermission {
  final String module;
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;

  const UserPermission({
    required this.module,
    this.canCreate = false,
    this.canRead = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) => UserPermission(
        module: json['module']?.toString() ?? '',
        canCreate: json['canCreate'] == true,
        canRead: json['canRead'] == true,
        canUpdate: json['canUpdate'] == true,
        canDelete: json['canDelete'] == true,
      );

  Map<String, dynamic> toJson() => {
        'module': module,
        'canCreate': canCreate,
        'canRead': canRead,
        'canUpdate': canUpdate,
        'canDelete': canDelete,
      };

  bool can(PermissionAction action) => switch (action) {
        PermissionAction.read => canRead,
        PermissionAction.create => canCreate,
        PermissionAction.update => canUpdate,
        PermissionAction.delete => canDelete,
      };

  UserPermission copyWith({
    bool? canCreate,
    bool? canRead,
    bool? canUpdate,
    bool? canDelete,
  }) =>
      UserPermission(
        module: module,
        canCreate: canCreate ?? this.canCreate,
        canRead: canRead ?? this.canRead,
        canUpdate: canUpdate ?? this.canUpdate,
        canDelete: canDelete ?? this.canDelete,
      );

  /// Trả bản sao với 1 action được set giá trị mới.
  UserPermission withAction(PermissionAction action, bool value) =>
      switch (action) {
        PermissionAction.read => copyWith(canRead: value),
        PermissionAction.create => copyWith(canCreate: value),
        PermissionAction.update => copyWith(canUpdate: value),
        PermissionAction.delete => copyWith(canDelete: value),
      };

  @override
  bool operator ==(Object other) =>
      other is UserPermission &&
      other.module == module &&
      other.canCreate == canCreate &&
      other.canRead == canRead &&
      other.canUpdate == canUpdate &&
      other.canDelete == canDelete;

  @override
  int get hashCode =>
      Object.hash(module, canCreate, canRead, canUpdate, canDelete);
}

/// Định nghĩa 1 module trong catalog: key backend, nhãn VN, phạm vi, tập action
/// LIÊN QUAN (chỉ những action có ý nghĩa mới hiện toggle), icon hiển thị.
@immutable
class PermissionModuleDef {
  final String module;
  final String label;
  final PermissionScope scope;
  final List<PermissionAction> actions;
  final IconData icon;

  const PermissionModuleDef({
    required this.module,
    required this.label,
    required this.scope,
    required this.actions,
    required this.icon,
  });
}

/// Catalog module + action liên quan (BE §26.2). Nguồn chân lý cho UI editor.
class PermissionCatalog {
  PermissionCatalog._();

  static const List<PermissionAction> _rcud = [
    PermissionAction.read,
    PermissionAction.create,
    PermissionAction.update,
    PermissionAction.delete,
  ];
  static const List<PermissionAction> _ru = [
    PermissionAction.read,
    PermissionAction.update,
  ];
  static const List<PermissionAction> _rud = [
    PermissionAction.read,
    PermissionAction.update,
    PermissionAction.delete,
  ];
  static const List<PermissionAction> _rc = [
    PermissionAction.read,
    PermissionAction.create,
  ];
  static const List<PermissionAction> _r = [PermissionAction.read];
  static const List<PermissionAction> _u = [PermissionAction.update];

  /// Module cấp hệ thống (admin-scope) — default all false.
  static const List<PermissionModuleDef> adminModules = [
    PermissionModuleDef(
      module: 'users',
      label: 'Người dùng',
      scope: PermissionScope.admin,
      actions: _rcud,
      icon: Icons.people_alt_rounded,
    ),
    PermissionModuleDef(
      module: 'kyc',
      label: 'Duyệt KYC',
      scope: PermissionScope.admin,
      actions: _ru,
      icon: Icons.verified_user_rounded,
    ),
    PermissionModuleDef(
      module: 'subscriptions',
      label: 'Gói đăng ký',
      scope: PermissionScope.admin,
      actions: _rcud,
      icon: Icons.card_membership_rounded,
    ),
    PermissionModuleDef(
      module: 'payments',
      label: 'Thanh toán',
      scope: PermissionScope.admin,
      actions: _ru,
      icon: Icons.payments_rounded,
    ),
    PermissionModuleDef(
      module: 'disputes',
      label: 'Khiếu nại',
      scope: PermissionScope.admin,
      actions: _ru,
      icon: Icons.gavel_rounded,
    ),
    PermissionModuleDef(
      module: 'reviewsModeration',
      label: 'Kiểm duyệt đánh giá',
      scope: PermissionScope.admin,
      actions: _rud,
      icon: Icons.rate_review_rounded,
    ),
    PermissionModuleDef(
      module: 'propertiesModeration',
      label: 'Kiểm duyệt cơ sở',
      scope: PermissionScope.admin,
      actions: _u,
      icon: Icons.apartment_rounded,
    ),
    PermissionModuleDef(
      module: 'audit',
      label: 'Nhật ký hệ thống',
      scope: PermissionScope.admin,
      actions: _r,
      icon: Icons.history_rounded,
    ),
    PermissionModuleDef(
      module: 'leads',
      label: 'Lead khách',
      scope: PermissionScope.admin,
      actions: _r,
      icon: Icons.person_search_rounded,
    ),
    PermissionModuleDef(
      module: 'support',
      label: 'Hỗ trợ',
      scope: PermissionScope.admin,
      actions: _ru,
      icon: Icons.support_agent_rounded,
    ),
    PermissionModuleDef(
      module: 'emails',
      label: 'Email hệ thống',
      scope: PermissionScope.admin,
      actions: _rc,
      icon: Icons.mail_rounded,
    ),
    PermissionModuleDef(
      module: 'billing',
      label: 'Bảng giá gói',
      scope: PermissionScope.admin,
      actions: _rcud,
      icon: Icons.request_quote_rounded,
    ),
    PermissionModuleDef(
      module: 'appVersion',
      label: 'Phiên bản app',
      scope: PermissionScope.admin,
      actions: _u,
      icon: Icons.system_update_rounded,
    ),
    PermissionModuleDef(
      module: 'dashboard',
      label: 'Bảng điều khiển',
      scope: PermissionScope.admin,
      actions: _r,
      icon: Icons.dashboard_rounded,
    ),
  ];

  /// Module theo chủ (owner-scope) — SALE hệ thống thường không cần.
  static const List<PermissionModuleDef> ownerModules = [
    PermissionModuleDef(
      module: 'properties',
      label: 'Cơ sở lưu trú',
      scope: PermissionScope.owner,
      actions: _rcud,
      icon: Icons.home_work_rounded,
    ),
    PermissionModuleDef(
      module: 'bookings',
      label: 'Đặt phòng',
      scope: PermissionScope.owner,
      actions: _rcud,
      icon: Icons.event_note_rounded,
    ),
    PermissionModuleDef(
      module: 'calendar',
      label: 'Lịch phòng',
      scope: PermissionScope.owner,
      actions: _rcud,
      icon: Icons.calendar_month_rounded,
    ),
    PermissionModuleDef(
      module: 'reviews',
      label: 'Đánh giá',
      scope: PermissionScope.owner,
      actions: _ru,
      icon: Icons.star_rounded,
    ),
  ];

  /// Toàn bộ module (admin + owner) — dùng khi gửi bulk PUT.
  static List<PermissionModuleDef> get all => [...adminModules, ...ownerModules];

  /// Tra định nghĩa theo key module.
  static PermissionModuleDef? byModule(String module) {
    for (final def in all) {
      if (def.module == module) return def;
    }
    return null;
  }
}
