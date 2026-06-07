/// Quyền của 1 nhân viên SALE theo module (`GET/PUT /permissions/:userId`).
/// Module whitelist (BE confirm): properties | bookings | calendar | reviews.
library;

const kPermissionModules = <(String, String)>[
  ('properties', 'Cơ sở / Phòng'),
  ('bookings', 'Booking'),
  ('calendar', 'Lịch phòng'),
  ('reviews', 'Đánh giá'),
];

class ModulePermission {
  final String module;
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;

  const ModulePermission({
    required this.module,
    this.canCreate = false,
    this.canRead = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  factory ModulePermission.fromJson(Map<String, dynamic> j) => ModulePermission(
        module: (j['module'] ?? '') as String,
        canCreate: (j['canCreate'] ?? false) as bool,
        canRead: (j['canRead'] ?? false) as bool,
        canUpdate: (j['canUpdate'] ?? false) as bool,
        canDelete: (j['canDelete'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
        'module': module,
        'canCreate': canCreate,
        'canRead': canRead,
        'canUpdate': canUpdate,
        'canDelete': canDelete,
      };

  ModulePermission copyWith({
    bool? canCreate,
    bool? canRead,
    bool? canUpdate,
    bool? canDelete,
  }) =>
      ModulePermission(
        module: module,
        canCreate: canCreate ?? this.canCreate,
        canRead: canRead ?? this.canRead,
        canUpdate: canUpdate ?? this.canUpdate,
        canDelete: canDelete ?? this.canDelete,
      );

  String get moduleLabel => kPermissionModules
      .firstWhere((m) => m.$1 == module, orElse: () => (module, module))
      .$2;
}

/// Kết quả `GET /permissions/:userId` — info user + danh sách quyền theo module.
/// Luôn trả về đủ 4 module (điền mặc định nếu BE thiếu module nào).
class StaffPermissions {
  final String userId;
  final String userName;
  final List<ModulePermission> modules;

  const StaffPermissions({
    required this.userId,
    required this.userName,
    required this.modules,
  });

  factory StaffPermissions.fromJson(Map<String, dynamic> data) {
    final user = data['user'];
    final raw = (data['permissions'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ModulePermission.fromJson)
            .toList() ??
        const <ModulePermission>[];
    // Đảm bảo đủ + đúng thứ tự 4 module.
    final byModule = {for (final p in raw) p.module: p};
    final modules = [
      for (final m in kPermissionModules)
        byModule[m.$1] ?? ModulePermission(module: m.$1),
    ];
    return StaffPermissions(
      userId: (user is Map ? user['id'] : data['userId']) as String? ?? '',
      userName: (user is Map ? user['name'] : null) as String? ?? '',
      modules: modules,
    );
  }

  StaffPermissions withModule(ModulePermission updated) => StaffPermissions(
        userId: userId,
        userName: userName,
        modules: [
          for (final m in modules) m.module == updated.module ? updated : m,
        ],
      );
}
