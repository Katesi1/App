import '../../../../core/constants/app_constants.dart';

class PermissionEntry {
  final String id;
  final String number;
  final String label;
  final bool enabled;

  const PermissionEntry({
    required this.id,
    required this.number,
    required this.label,
    required this.enabled,
  });

  PermissionEntry copyWith({bool? enabled}) => PermissionEntry(
        id: id,
        number: number,
        label: label,
        enabled: enabled ?? this.enabled,
      );
}

class PermissionSubGroup {
  final String id;
  final String number;
  final String label;
  final List<PermissionEntry> entries;

  const PermissionSubGroup({
    required this.id,
    required this.number,
    required this.label,
    required this.entries,
  });

  bool get allEnabled => entries.every((e) => e.enabled);
  bool get anyEnabled => entries.any((e) => e.enabled);

  PermissionSubGroup withEntryToggled(String entryId) => PermissionSubGroup(
        id: id,
        number: number,
        label: label,
        entries: entries
            .map((e) => e.id == entryId ? e.copyWith(enabled: !e.enabled) : e)
            .toList(),
      );

  PermissionSubGroup withAllEnabled(bool value) => PermissionSubGroup(
        id: id,
        number: number,
        label: label,
        entries: entries.map((e) => e.copyWith(enabled: value)).toList(),
      );
}

class PermissionGroup {
  final String id;
  final String number;
  final String label;
  final List<PermissionSubGroup> subGroups;

  const PermissionGroup({
    required this.id,
    required this.number,
    required this.label,
    required this.subGroups,
  });

  bool get allEnabled => subGroups.every((sg) => sg.allEnabled);
  bool get anyEnabled => subGroups.any((sg) => sg.anyEnabled);

  PermissionGroup withSubGroupToggled(String subGroupId) => PermissionGroup(
        id: id,
        number: number,
        label: label,
        subGroups: subGroups.map((sg) {
          if (sg.id != subGroupId) return sg;
          return sg.withAllEnabled(!sg.allEnabled);
        }).toList(),
      );

  PermissionGroup withEntryToggled(String subGroupId, String entryId) =>
      PermissionGroup(
        id: id,
        number: number,
        label: label,
        subGroups: subGroups.map((sg) {
          if (sg.id != subGroupId) return sg;
          return sg.withEntryToggled(entryId);
        }).toList(),
      );

  PermissionGroup withAllEnabled(bool value) => PermissionGroup(
        id: id,
        number: number,
        label: label,
        subGroups: subGroups.map((sg) => sg.withAllEnabled(value)).toList(),
      );
}

/// Defines module structure + default enabled state per role.
class PermissionDefinitions {
  static List<PermissionGroup> defaultsForRole(UserRole role) {
    final defaults = _defaultEnabled[role] ?? {};
    return _structure
        .map((group) => PermissionGroup(
              id: group.id,
              number: group.number,
              label: group.label,
              subGroups: group.subGroups
                  .map((sub) => PermissionSubGroup(
                        id: sub.id,
                        number: sub.number,
                        label: sub.label,
                        entries: sub.entries
                            .map((e) => PermissionEntry(
                                  id: e.id,
                                  number: e.number,
                                  label: e.label,
                                  enabled: defaults[e.id] ?? false,
                                ))
                            .toList(),
                      ))
                  .toList(),
            ))
        .toList();
  }

  /// Applies saved enabled states onto the default structure.
  static List<PermissionGroup> applyOverrides(
    UserRole role,
    Map<String, bool> saved,
  ) {
    final base = defaultsForRole(role);
    if (saved.isEmpty) return base;
    return base
        .map((group) => PermissionGroup(
              id: group.id,
              number: group.number,
              label: group.label,
              subGroups: group.subGroups
                  .map((sub) => PermissionSubGroup(
                        id: sub.id,
                        number: sub.number,
                        label: sub.label,
                        entries: sub.entries
                            .map((e) => e.copyWith(
                                  enabled: saved.containsKey(e.id)
                                      ? saved[e.id]!
                                      : e.enabled,
                                ))
                            .toList(),
                      ))
                  .toList(),
            ))
        .toList();
  }

  /// Flattens all entries to id→enabled map for storage.
  static Map<String, bool> toMap(List<PermissionGroup> groups) {
    final map = <String, bool>{};
    for (final group in groups) {
      for (final sub in group.subGroups) {
        for (final entry in sub.entries) {
          map[entry.id] = entry.enabled;
        }
      }
    }
    return map;
  }

  // Module structure (no enabled — shape definition only).

  static final List<PermissionGroup> _structure = [
    PermissionGroup(
      id: '01',
      number: '01',
      label: 'Quản lý Phòng',
      subGroups: [
        PermissionSubGroup(
          id: '1.1',
          number: '1.1',
          label: 'Danh sách phòng',
          entries: [
            _e('room.list.view', '1.1.1', 'Xem'),
            _e('room.list.create', '1.1.2', 'Thêm mới'),
            _e('room.list.update', '1.1.3', 'Chỉnh sửa'),
            _e('room.list.delete', '1.1.4', 'Xóa'),
          ],
        ),
        PermissionSubGroup(
          id: '1.2',
          number: '1.2',
          label: 'Hình ảnh & Giá phòng',
          entries: [
            _e('room.media.view', '1.2.1', 'Xem'),
            _e('room.media.update', '1.2.2', 'Cập nhật'),
          ],
        ),
      ],
    ),
    PermissionGroup(
      id: '02',
      number: '02',
      label: 'Quản lý Booking',
      subGroups: [
        PermissionSubGroup(
          id: '2.1',
          number: '2.1',
          label: 'Danh sách booking',
          entries: [
            _e('booking.list.view', '2.1.1', 'Xem'),
            _e('booking.list.hold', '2.1.2', 'Đặt giữ phòng'),
          ],
        ),
        PermissionSubGroup(
          id: '2.2',
          number: '2.2',
          label: 'Xử lý booking',
          entries: [
            _e('booking.action.confirm', '2.2.1', 'Xác nhận'),
            _e('booking.action.cancel', '2.2.2', 'Huỷ'),
          ],
        ),
      ],
    ),
    PermissionGroup(
      id: '03',
      number: '03',
      label: 'Lịch phòng',
      subGroups: [
        PermissionSubGroup(
          id: '3.1',
          number: '3.1',
          label: 'Xem lịch',
          entries: [
            _e('calendar.view', '3.1.1', 'Xem'),
          ],
        ),
        PermissionSubGroup(
          id: '3.2',
          number: '3.2',
          label: 'Khoá / mở phòng',
          entries: [
            _e('calendar.lock', '3.2.1', 'Thực hiện'),
          ],
        ),
      ],
    ),
    PermissionGroup(
      id: '04',
      number: '04',
      label: 'Báo cáo',
      subGroups: [
        PermissionSubGroup(
          id: '4.1',
          number: '4.1',
          label: 'Xem báo cáo',
          entries: [
            _e('report.view', '4.1.1', 'Xem'),
          ],
        ),
      ],
    ),
    PermissionGroup(
      id: '05',
      number: '05',
      label: 'Cơ sở lưu trú',
      subGroups: [
        PermissionSubGroup(
          id: '5.1',
          number: '5.1',
          label: 'Danh sách cơ sở',
          entries: [
            _e('property.list.view', '5.1.1', 'Xem'),
            _e('property.list.create', '5.1.2', 'Thêm mới'),
            _e('property.list.update', '5.1.3', 'Chỉnh sửa'),
            _e('property.list.delete', '5.1.4', 'Xóa'),
          ],
        ),
      ],
    ),
    PermissionGroup(
      id: '06',
      number: '06',
      label: 'Khách hàng',
      subGroups: [
        PermissionSubGroup(
          id: '6.1',
          number: '6.1',
          label: 'Danh sách khách',
          entries: [
            _e('customer.list.view', '6.1.1', 'Xem'),
          ],
        ),
      ],
    ),
  ];

  static PermissionEntry _e(String id, String number, String label) =>
      PermissionEntry(id: id, number: number, label: label, enabled: false);

  // ─── Default enabled states theo role ──────────────────────────────────────

  static const Map<UserRole, Map<String, bool>> _defaultEnabled = {
    UserRole.sale: {
      'room.list.view': true,
      'room.media.view': true,
      'booking.list.view': true,
      'booking.list.hold': true,
      'booking.action.confirm': true,
      'calendar.view': true,
    },
    UserRole.owner: {
      'room.list.view': true,
      'room.list.create': true,
      'room.list.update': true,
      'room.list.delete': true,
      'room.media.view': true,
      'room.media.update': true,
      'booking.list.view': true,
      'booking.list.hold': true,
      'booking.action.confirm': true,
      'booking.action.cancel': true,
      'calendar.view': true,
      'calendar.lock': true,
      'report.view': true,
      'property.list.view': true,
      'property.list.create': true,
      'property.list.update': true,
      'property.list.delete': true,
      'customer.list.view': true,
    },
  };
}
