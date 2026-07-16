import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../controllers/permission_controller.dart';
import '../data/models/user_permission.dart';

/// Editor phân quyền per-user cho 1 SALE hệ thống.
///
/// Load `GET /permissions/:userId`, hiển thị module theo nhóm (Admin-scope /
/// Owner-scope), mỗi module 1 card với các toggle action liên quan. Lưu qua
/// `PUT /permissions/:userId`.
class PermissionEditorScreen extends ConsumerWidget {
  final String userId;
  final String userName;

  const PermissionEditorScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final permsAsync = ref.watch(userPermissionsProvider(userId));

    return Scaffold(
      backgroundColor: colors.bgSurfaceContainer,
      body: Column(
        children: [
          _Header(userName: userName),
          Expanded(
            child: permsAsync.when(
              data: (perms) => _Editor(
                key: ValueKey(userId),
                userId: userId,
                initial: perms,
              ),
              loading: () => const SkeletonList(
                skeleton: DetailSkeleton(),
                count: 1,
              ),
              error: (e, _) => RefreshableMessage(
                child: ErrorStateWidget(
                  message: e.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.invalidate(userPermissionsProvider(userId)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String userName;

  const _Header({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.jade900, AppColors.jade500],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 20,
          bottom: 18,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -50,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.jade300.withValues(alpha: 0.10),
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isNotEmpty ? userName : 'Phân quyền',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Cấp quyền truy cập hệ thống',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Editor (local mutable state) ──────────────────────────────────────────────

class _Editor extends ConsumerStatefulWidget {
  final String userId;
  final List<UserPermission> initial;

  const _Editor({
    super.key,
    required this.userId,
    required this.initial,
  });

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  /// module → UserPermission (mutable local copy).
  late Map<String, UserPermission> _perms;
  bool _ownerExpanded = false;

  @override
  void initState() {
    super.initState();
    _perms = _seed(widget.initial);
  }

  Map<String, UserPermission> _seed(List<UserPermission> initial) {
    final byModule = {for (final p in initial) p.module: p};
    final map = <String, UserPermission>{};
    for (final def in PermissionCatalog.all) {
      map[def.module] =
          byModule[def.module] ?? UserPermission(module: def.module);
    }
    return map;
  }

  void _toggleAction(String module, PermissionAction action, bool value) {
    final current = _perms[module];
    if (current == null) return;
    setState(() {
      _perms = {..._perms, module: current.withAction(action, value)};
    });
  }

  void _setModuleAll(PermissionModuleDef def, bool value) {
    var updated = _perms[def.module] ?? UserPermission(module: def.module);
    for (final action in def.actions) {
      updated = updated.withAction(action, value);
    }
    setState(() => _perms = {..._perms, def.module: updated});
  }

  bool _moduleAllOn(PermissionModuleDef def) {
    final p = _perms[def.module];
    if (p == null) return false;
    return def.actions.every((a) => p.can(a));
  }

  Future<void> _save() async {
    // Gửi đầy đủ toàn bộ catalog module (bulk upsert, đủ 4 field).
    final payload = PermissionCatalog.all
        .map((def) => _perms[def.module] ?? UserPermission(module: def.module))
        .toList();
    final ok = await ref
        .read(permissionSaveProvider.notifier)
        .save(widget.userId, payload);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã lưu phân quyền');
      Navigator.of(context).maybePop();
    } else {
      final error = ref.read(permissionSaveProvider).error;
      AppSnackBar.error(
        context,
        error?.toString().replaceAll('Exception: ', '') ??
            'Lưu phân quyền thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(permissionSaveProvider).isLoading;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            children: [
              const _SectionLabel(
                icon: Icons.shield_rounded,
                label: 'Quyền hệ thống (admin)',
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < PermissionCatalog.adminModules.length; i++)
                _ModuleCard(
                  def: PermissionCatalog.adminModules[i],
                  permission: _perms[PermissionCatalog.adminModules[i].module]!,
                  allOn: _moduleAllOn(PermissionCatalog.adminModules[i]),
                  onToggleAction: _toggleAction,
                  onToggleAll: _setModuleAll,
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: (i * 25).ms)
                    .slideY(begin: 0.04, end: 0, duration: 200.ms),
              const SizedBox(height: 14),
              _OwnerScopeHeader(
                expanded: _ownerExpanded,
                onTap: () =>
                    setState(() => _ownerExpanded = !_ownerExpanded),
              ),
              if (_ownerExpanded) ...[
                const SizedBox(height: 10),
                for (final def in PermissionCatalog.ownerModules)
                  _ModuleCard(
                    def: def,
                    permission: _perms[def.module]!,
                    allOn: _moduleAllOn(def),
                    onToggleAction: _toggleAction,
                    onToggleAll: _setModuleAll,
                  ),
              ],
            ],
          ),
        ),
        _BottomBar(saving: saving, onSave: _save),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 15, color: colors.textTertiary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ── Owner-scope collapsible header ────────────────────────────────────────────

class _OwnerScopeHeader extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _OwnerScopeHeader({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.person_pin_rounded, size: 15, color: colors.textTertiary),
            const SizedBox(width: 6),
            Text(
              'QUYỀN THEO CHỦ (OWNER)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: colors.textTertiary,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textTertiary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Module card ───────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final PermissionModuleDef def;
  final UserPermission permission;
  final bool allOn;
  final void Function(String module, PermissionAction action, bool value)
      onToggleAction;
  final void Function(PermissionModuleDef def, bool value) onToggleAll;

  const _ModuleCard({
    required this.def,
    required this.permission,
    required this.allOn,
    required this.onToggleAction,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final grantedCount = def.actions.where((a) => permission.can(a)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(def.icon, size: 18, color: colors.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.label,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        grantedCount == 0
                            ? 'Chưa cấp quyền'
                            : 'Đã cấp $grantedCount/${def.actions.length}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: grantedCount == 0
                              ? colors.textTertiary
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onToggleAll(def, !allOn),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    allOn ? 'Bỏ tất cả' : 'Chọn tất cả',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.borderDefault),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in def.actions)
                  _ActionChip(
                    action: action,
                    value: permission.can(action),
                    onChanged: (v) =>
                        onToggleAction(def.module, action, v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action chip (bật/tắt 1 action) ────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final PermissionAction action;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ActionChip({
    required this.action,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _actionColor(action);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? accent.withValues(alpha: 0.12)
              : colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: value ? accent.withValues(alpha: 0.6) : colors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value
                  ? Icons.check_circle_rounded
                  : _actionIcon(action),
              size: 15,
              color: value ? accent : colors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                color: value ? accent : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool saving;
  final Future<void> Function() onSave;

  const _BottomBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : () => onSave(),
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 16),
          label: Text(
            saving ? 'Đang lưu...' : 'Lưu thay đổi',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: colors.brand,
            foregroundColor: colors.textOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _actionColor(PermissionAction action) => switch (action) {
      PermissionAction.read => AppColors.jade500,
      PermissionAction.create => AppColors.success,
      PermissionAction.update => AppColors.warning,
      PermissionAction.delete => AppColors.error,
    };

IconData _actionIcon(PermissionAction action) => switch (action) {
      PermissionAction.read => Icons.visibility_rounded,
      PermissionAction.create => Icons.add_circle_outline_rounded,
      PermissionAction.update => Icons.edit_rounded,
      PermissionAction.delete => Icons.remove_circle_outline_rounded,
    };
