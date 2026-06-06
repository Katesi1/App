import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  static const _roles = [UserRole.sale, UserRole.owner];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _roles.map((role) => _RoleTab(role: role)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.jade900, AppColors.jade500],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 16,
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
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold500.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                            'Phân quyền vai trò',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Quản lý quyền hạn cho từng vai trò',
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
          _RoleTabBar(tabController: _tabController, roles: _roles),
        ],
      ),
    );
  }
}

// ── Custom TabBar ─────────────────────────────────────────────────────────────

class _RoleTabBar extends ConsumerWidget {
  final TabController tabController;
  final List<UserRole> roles;

  const _RoleTabBar({required this.tabController, required this.roles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
      child: TabBar(
        controller: tabController,
        labelPadding: EdgeInsets.zero,
        indicatorColor: Colors.white,
        indicatorWeight: 2.5,
        dividerColor: Colors.transparent,
        tabs: roles.map((role) {
          final groups = ref.watch(rolePermissionsProvider(role));
          final total = groups.fold<int>(
            0,
            (sum, g) =>
                sum + g.subGroups.fold(0, (s, sg) => s + sg.entries.length),
          );
          final enabled = groups.fold<int>(
            0,
            (sum, g) =>
                sum +
                g.subGroups.fold(
                  0,
                  (s, sg) => s + sg.entries.where((e) => e.enabled).length,
                ),
          );

          final isSelected = tabController.index == roles.indexOf(role);

          return Tab(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _roleIcon(role),
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role == UserRole.sale ? 'Nhân viên' : 'Chủ nhà',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      if (total > 0)
                        Text(
                          '$enabled/$total quyền',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Role Tab ──────────────────────────────────────────────────────────────────

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            itemCount: groups.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _RoleHeaderCard(role: role, groups: groups);
              }
              final group = groups[i - 1];
              return _GroupTile(group: group, role: role)
                  .animate()
                  .fadeIn(duration: 220.ms, delay: (i * 35).ms)
                  .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 220.ms,
                    delay: (i * 35).ms,
                  );
            },
          ),
        ),
        _BottomBar(role: role),
      ],
    );
  }
}

// ── Role Header Card ──────────────────────────────────────────────────────────

class _RoleHeaderCard extends StatelessWidget {
  final UserRole role;
  final List<PermissionGroup> groups;

  const _RoleHeaderCard({required this.role, required this.groups});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _roleAccent(role);

    final total = groups.fold<int>(
      0,
      (sum, g) => sum + g.subGroups.fold(0, (s, sg) => s + sg.entries.length),
    );
    final enabled = groups.fold<int>(
      0,
      (sum, g) =>
          sum +
          g.subGroups.fold(
            0,
            (s, sg) => s + sg.entries.where((e) => e.enabled).length,
          ),
    );
    final progress = total > 0 ? enabled / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_roleIcon(role), color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      role == UserRole.sale ? 'Nhân viên Sale' : 'Chủ nhà',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$enabled/$total',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  role == UserRole.sale
                      ? 'Quản lý booking, phòng & lịch'
                      : 'Toàn quyền quản lý cơ sở & nhân viên',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: accent.withValues(alpha: 0.14),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.04, end: 0, duration: 300.ms);
  }
}

// ── Group Tile ────────────────────────────────────────────────────────────────

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

    final totalEntries =
        group.subGroups.fold<int>(0, (sum, sg) => sum + sg.entries.length);
    final enabledEntries = group.subGroups.fold<int>(
      0,
      (sum, sg) => sum + sg.entries.where((e) => e.enabled).length,
    );

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
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom:
                  _expanded ? Radius.zero : const Radius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Group icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _groupIcon(group.id),
                      size: 18,
                      color: colors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.label,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$enabledEntries/$totalEntries quyền đã bật',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: anyEnabled
                                ? colors.textSecondary
                                : colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GroupSwitch(
                    value: allEnabled,
                    indeterminate: !allEnabled && anyEnabled,
                    onChanged: (_) => ref
                        .read(
                          rolePermissionsProvider(widget.role).notifier,
                        )
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

// ── SubGroup Tile ─────────────────────────────────────────────────────────────

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
    final enabledCount = sub.entries.where((e) => e.enabled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                // Vertical line + indent
                Container(
                  width: 3,
                  height: 28,
                  margin: const EdgeInsets.only(left: 7, right: 14),
                  decoration: BoxDecoration(
                    color: anyEnabled
                        ? colors.brand.withValues(alpha: 0.35)
                        : colors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.label,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (!_expanded)
                        Text(
                          '$enabledCount/${sub.entries.length}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10,
                            color: colors.textTertiary,
                          ),
                        ),
                    ],
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
            ),
        if (!widget.isLast)
          Divider(
            height: 1,
            color: colors.borderDefault,
            indent: 20,
          ),
      ],
    );
  }
}

// ── Entry Row ─────────────────────────────────────────────────────────────────

class _EntryRow extends ConsumerWidget {
  final PermissionEntry entry;
  final String groupId;
  final String subGroupId;
  final UserRole role;
  final bool isLastInSub;

  const _EntryRow({
    required this.entry,
    required this.groupId,
    required this.subGroupId,
    required this.role,
    required this.isLastInSub,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final opData = _operationData(entry.id);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(58, 9, 14, 9),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: opData.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(opData.icon, size: 13, color: opData.color),
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
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: entry.enabled,
                  onChanged: (_) => ref
                      .read(rolePermissionsProvider(role).notifier)
                      .toggleEntry(groupId, subGroupId, entry.id),
                  activeThumbColor: colors.brand,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        if (!isLastInSub)
          Divider(
            height: 1,
            color: colors.borderDefault,
            indent: 58,
          ),
      ],
    );
  }
}

// ── Custom Group Switch ───────────────────────────────────────────────────────

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
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 24,
        decoration: BoxDecoration(
          color: (value || indeterminate)
              ? effectiveColor.withValues(alpha: 0.9)
              : colors.borderDefault,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: indeterminate && !value
                    ? Center(
                        child: Container(
                          width: 7,
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

// ── Bottom Bar ────────────────────────────────────────────────────────────────

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
            child: OutlinedButton.icon(
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
              icon: Icon(
                Icons.restart_alt_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
              label: Text(
                'Mặc định',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () async {
                await ref.read(rolePermissionsProvider(role).notifier).save();
                if (context.mounted) {
                  AppSnackBar.success(context, 'Đã lưu phân quyền');
                }
              },
              icon: const Icon(Icons.save_rounded, size: 16),
              label: Text(
                'Lưu thay đổi',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: colors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _roleAccent(UserRole role) => switch (role) {
      UserRole.sale => AppColors.jade500,
      UserRole.owner => AppColors.warning,
      _ => AppColors.jade500,
    };

IconData _roleIcon(UserRole role) => switch (role) {
      UserRole.sale => Icons.badge_rounded,
      UserRole.owner => Icons.home_work_rounded,
      _ => Icons.person_rounded,
    };

IconData _groupIcon(String groupId) => switch (groupId) {
      '01' => Icons.bed_rounded,
      '02' => Icons.event_note_rounded,
      '03' => Icons.calendar_month_rounded,
      '04' => Icons.analytics_rounded,
      '05' => Icons.apartment_rounded,
      '06' => Icons.people_rounded,
      _ => Icons.settings_rounded,
    };

({IconData icon, Color color}) _operationData(String entryId) {
  final op = entryId.split('.').last;
  return switch (op) {
    'view' => (icon: Icons.visibility_rounded, color: AppColors.jade500),
    'create' => (
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.success
      ),
    'update' => (icon: Icons.edit_rounded, color: AppColors.warning),
    'delete' => (
        icon: Icons.remove_circle_outline_rounded,
        color: AppColors.error
      ),
    'hold' => (icon: Icons.lock_clock_rounded, color: AppColors.jade300),
    'confirm' => (
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success
      ),
    'cancel' => (icon: Icons.cancel_outlined, color: AppColors.error),
    'lock' => (icon: Icons.lock_outline_rounded, color: AppColors.warning),
    _ => (icon: Icons.circle_outlined, color: AppColors.slate400),
  };
}
