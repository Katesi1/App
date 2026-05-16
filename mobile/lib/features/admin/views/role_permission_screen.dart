import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/permission_controller.dart';
import '../data/models/permission_model.dart';

class RolePermissionScreen extends ConsumerStatefulWidget {
  const RolePermissionScreen({super.key});

  @override
  ConsumerState<RolePermissionScreen> createState() =>
      _RolePermissionScreenState();
}

class _RolePermissionScreenState extends ConsumerState<RolePermissionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Chỉ SALE và OWNER có thể cấu hình (ADMIN luôn full quyền)
  static const _roles = [UserRole.sale, UserRole.owner];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgSurfaceContainer,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Phân quyền theo vai trò',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.brand,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.brand,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: _roles
              .map((r) => Tab(text: r == UserRole.sale ? 'Nhân viên' : 'Chủ nhà'))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _roles
            .map((role) => _RoleTab(role: role))
            .toList(),
      ),
    );
  }
}

class _RoleTab extends ConsumerWidget {
  final UserRole role;

  const _RoleTab({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(rolePermissionsProvider(role));
    if (groups.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: groups.length,
            itemBuilder: (context, i) => _GroupTile(
              group: groups[i],
              role: role,
            ),
          ),
        ),
        _BottomBar(role: role),
      ],
    );
  }
}

class _GroupTile extends ConsumerStatefulWidget {
  final PermissionGroup group;
  final UserRole role;

  const _GroupTile({required this.group, required this.role});

  @override
  ConsumerState<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends ConsumerState<_GroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final group = widget.group;
    final allEnabled = group.allEnabled;
    final anyEnabled = group.anyEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          // ── Group header row ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom: _expanded
                  ? Radius.zero
                  : const Radius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      group.number,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.label,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  _GroupSwitch(
                    value: allEnabled,
                    indeterminate: !allEnabled && anyEnabled,
                    onChanged: (_) => ref
                        .read(rolePermissionsProvider(widget.role).notifier)
                        .toggleGroup(group.id),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
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
          ),

          // ── SubGroups ────────────────────────────────────────────────
          if (_expanded) ...[
            Divider(height: 1, color: colors.borderDefault),
            for (final sub in group.subGroups)
              _SubGroupTile(
                sub: sub,
                groupId: group.id,
                role: widget.role,
                isLast: sub == group.subGroups.last,
              ),
          ],
        ],
      ),
    );
  }
}

class _SubGroupTile extends ConsumerStatefulWidget {
  final PermissionSubGroup sub;
  final String groupId;
  final UserRole role;
  final bool isLast;

  const _SubGroupTile({
    required this.sub,
    required this.groupId,
    required this.role,
    required this.isLast,
  });

  @override
  ConsumerState<_SubGroupTile> createState() => _SubGroupTileState();
}

class _SubGroupTileState extends ConsumerState<_SubGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sub = widget.sub;
    final allEnabled = sub.allEnabled;
    final anyEnabled = sub.anyEnabled;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    sub.number,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sub.label,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                _GroupSwitch(
                  value: allEnabled,
                  indeterminate: !allEnabled && anyEnabled,
                  onChanged: (_) => ref
                      .read(rolePermissionsProvider(widget.role).notifier)
                      .toggleSubGroup(widget.groupId, sub.id),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.textTertiary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_expanded)
          for (final entry in sub.entries)
            _EntryRow(
              entry: entry,
              groupId: widget.groupId,
              subGroupId: sub.id,
              role: widget.role,
              isLastInSub: entry == sub.entries.last,
              isLastSub: widget.isLast,
            ),

        if (!widget.isLast || _expanded)
          Divider(
            height: 1,
            color: colors.borderDefault,
            indent: _expanded ? 0 : 20,
          ),
      ],
    );
  }
}

class _EntryRow extends ConsumerWidget {
  final PermissionEntry entry;
  final String groupId;
  final String subGroupId;
  final UserRole role;
  final bool isLastInSub;
  final bool isLastSub;

  const _EntryRow({
    required this.entry,
    required this.groupId,
    required this.subGroupId,
    required this.role,
    required this.isLastInSub,
    required this.isLastSub,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(54, 8, 14, 8),
          child: Row(
            children: [
              Text(
                entry.number,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: entry.enabled,
                onChanged: (_) => ref
                    .read(rolePermissionsProvider(role).notifier)
                    .toggleEntry(groupId, subGroupId, entry.id),
                activeThumbColor: colors.brand,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        if (!isLastInSub)
          Divider(
            height: 1,
            color: colors.borderDefault,
            indent: 54,
          ),
      ],
    );
  }
}

class _GroupSwitch extends StatelessWidget {
  final bool value;
  final bool indeterminate;
  final ValueChanged<bool> onChanged;

  const _GroupSwitch({
    required this.value,
    required this.indeterminate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveColor = indeterminate ? AppColors.warning : colors.brand;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 22,
        decoration: BoxDecoration(
          color: (value || indeterminate)
              ? effectiveColor.withValues(alpha: 0.9)
              : colors.borderDefault,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: indeterminate && !value
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final UserRole role;

  const _BottomBar({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final confirm = await _confirmReset(context);
                if (confirm == true) {
                  await ref
                      .read(rolePermissionsProvider(role).notifier)
                      .resetToDefaults();
                  if (context.mounted) {
                    AppSnackBar.info(context, 'Đã đặt lại về mặc định');
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Mặc định',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () async {
                await ref
                    .read(rolePermissionsProvider(role).notifier)
                    .save();
                if (context.mounted) {
                  AppSnackBar.success(context, 'Đã lưu phân quyền');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Lưu thay đổi',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmReset(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Đặt lại về mặc định?'),
          content: const Text('Mọi thay đổi tuỳ chỉnh sẽ bị mất.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đặt lại'),
            ),
          ],
        ),
      );
}
