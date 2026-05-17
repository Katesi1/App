import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/permission_model.dart';

class PermissionNotifier extends StateNotifier<List<PermissionGroup>> {
  PermissionNotifier(this._role) : super([]) {
    _load();
  }

  final UserRole _role;
  static const String _keyPrefix = 'role_permissions_v1_';

  String get _storageKey => '$_keyPrefix${_role.value}';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _readMap(prefs);
    state = PermissionDefinitions.applyOverrides(_role, saved);
  }

  Map<String, bool> _readMap(SharedPreferences prefs) {
    final keys = prefs.getKeys().where((k) => k.startsWith('${_storageKey}_'));
    final map = <String, bool>{};
    for (final k in keys) {
      final entryId = k.substring('${_storageKey}_'.length);
      map[entryId] = prefs.getBool(k) ?? false;
    }
    return map;
  }

  void toggleGroup(String groupId) {
    final updated = state.map((g) {
      if (g.id != groupId) return g;
      return g.withAllEnabled(!g.allEnabled);
    }).toList();
    state = updated;
  }

  void toggleSubGroup(String groupId, String subGroupId) {
    final updated = state.map((g) {
      if (g.id != groupId) return g;
      return g.withSubGroupToggled(subGroupId);
    }).toList();
    state = updated;
  }

  void toggleEntry(String groupId, String subGroupId, String entryId) {
    final updated = state.map((g) {
      if (g.id != groupId) return g;
      return g.withEntryToggled(subGroupId, entryId);
    }).toList();
    state = updated;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = PermissionDefinitions.toMap(state);
    for (final entry in map.entries) {
      await prefs.setBool('${_storageKey}_${entry.key}', entry.value);
    }
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove =
        prefs.getKeys().where((k) => k.startsWith('${_storageKey}_')).toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
    state = PermissionDefinitions.defaultsForRole(_role);
  }
}

final rolePermissionsProvider = StateNotifierProvider.family<PermissionNotifier,
    List<PermissionGroup>, UserRole>(
  (ref, role) => PermissionNotifier(role),
);
