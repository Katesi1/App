import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/user_controller.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  // null = tất cả nhân viên (OWNER + SALE, loại trừ ADMIN)
  int? _roleFilter;

  // 1=OWNER, 2=SALE
  static const _filterRoles = [2, 1];
  static const _filterLabels = ['Sale', 'Chủ nhà'];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.isAdmin ?? false;
    final userName = currentUser?.name ?? currentUser?.phone ?? '';

    final usersAsync = ref.watch(staffListProvider);

    return AppScaffold(
      title: 'Nhân viên',
      selectedIndex: 4,
      showAppBar: false,
      floatingActionButton: _buildFab(context, isAdmin),
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────
          _buildHeader(context, userName, isAdmin),

          // ── Filter chips (ADMIN only) ───────────────────────────
          if (isAdmin) _buildFilterChips(context),

          // ── List ────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => SkeletonList(
                skeleton: const _UserCardSkeleton(),
                count: 6,
              ),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(staffListProvider),
              ),
              data: (allUsers) {
                // Loại Admin ra khỏi danh sách quản lý
                final users = allUsers
                    .where((u) => !u.isAdmin)
                    .toList();

                if (users.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline_rounded,
                    message: isAdmin
                        ? (_roleFilter == null
                            ? 'Chưa có nhân viên nào'
                            : 'Không có ${AppHelpers.roleLabel(_roleFilter)} nào')
                        : 'Chưa có nhân viên trong đội',
                    onAction: isAdmin
                        ? () => context.push('/admin/users/new')
                        : () => _showAvailableStaffSheet(context),
                    actionLabel: isAdmin ? 'Thêm nhân viên' : 'Thêm vào đội',
                  );
                }

                return RefreshIndicator(
                  color: AppColors.ocean,
                  onRefresh: () async =>
                      ref.invalidate(staffListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _UserCard(
                      user: users[i],
                      animIndex: i,
                      isAdmin: isAdmin,
                      onTap: isAdmin
                          ? () => context
                              .push('/admin/users/${users[i].id}/edit')
                          : null,
                      onToggleActive: isAdmin
                          ? () => _toggleActive(context, users[i])
                          : null,
                      onRemoveStaff: !isAdmin
                          ? () => _removeStaff(context, users[i])
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.oceanDeep, AppColors.ocean],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circles
          Positioned(
            right: -50,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? 'Quản lý nhân viên' : 'Nhân viên của tôi',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAdmin
                          ? 'Gán vai trò · Kích hoạt tài khoản'
                          : 'Thêm nhân viên bằng số điện thoại',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.gold],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty
                          ? userName[0].toUpperCase()
                          : 'A',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: const Text('Tất cả'),
              selected: _roleFilter == null,
              onSelected: (_) => setState(() => _roleFilter = null),
              selectedColor: colors.primary.withValues(alpha: 0.15),
              checkmarkColor: colors.primary,
              labelStyle: GoogleFonts.beVietnamPro(
                fontWeight: _roleFilter == null
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: _roleFilter == null
                    ? colors.primary
                    : colors.onSurface,
                fontSize: 12,
              ),
            ),
          ),
          ...List.generate(_filterRoles.length, (i) {
            final role = _filterRoles[i];
            final color = AppHelpers.roleColor(role);
            final selected = _roleFilter == role;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(_filterLabels[i]),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _roleFilter = role),
                selectedColor: color.withValues(alpha: 0.15),
                checkmarkColor: color,
                labelStyle: GoogleFonts.beVietnamPro(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : colors.onSurface,
                  fontSize: 12,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.oceanMid, AppColors.ocean],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: isAdmin
            ? () => context.push('/admin/users/new')
            : () => _showAvailableStaffSheet(context),
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          isAdmin ? 'Thêm nhân viên' : 'Thêm vào đội',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
      ),
    );
  }

  /// OWNER xem danh sách SALE chưa gán → tap để thêm vào đội
  Future<void> _showAvailableStaffSheet(BuildContext context) async {
    final repo = ref.read(userRepositoryProvider);
    final result = await repo.getAvailableStaff();

    if (!context.mounted) return;

    if (!result.success) {
      AppSnackBar.error(context, result.message);
      return;
    }

    final available = result.data ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.person_add_rounded,
                      color: AppColors.ocean, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm nhân viên vào đội',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          '${available.length} nhân viên có thể thêm',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // List
            if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 48, color: AppColors.slate),
                    const SizedBox(height: 12),
                    Text(
                      'Không có nhân viên nào sẵn sàng',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nhân viên cần đăng ký tài khoản trước',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: available.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.border,
                    indent: 68,
                  ),
                  itemBuilder: (_, i) {
                    final sale = available[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.teal.withValues(alpha: 0.12),
                        child: Text(
                          sale.name.isNotEmpty
                              ? sale.name[0].toUpperCase()
                              : 'S',
                          style: GoogleFonts.beVietnamPro(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        sale.name.isNotEmpty ? sale.name : 'Chưa đặt tên',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      subtitle: Text(
                        sale.email ?? sale.phone,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      trailing: FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _addStaffByEmail(context, sale.email ?? '');
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('Thêm',
                            style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ocean,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addStaffByEmail(BuildContext context, String email) async {
    final repo = ref.read(userRepositoryProvider);
    final response = await repo.addMyStaff(email);
    if (!context.mounted) return;

    if (response.success) {
      ref.invalidate(staffListProvider);
      AppSnackBar.success(context, 'Đã thêm nhân viên thành công');
    } else {
      AppSnackBar.error(context, response.message);
    }
  }

  /// OWNER gỡ nhân viên khỏi đội
  Future<void> _removeStaff(BuildContext context, UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Gỡ nhân viên',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Gỡ "${user.name}" khỏi đội của bạn? Nhân viên này sẽ không thể xem phòng và lịch của bạn nữa.',
          style: GoogleFonts.beVietnamPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ',
                style: GoogleFonts.beVietnamPro(color: AppColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Gỡ',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final repo = ref.read(userRepositoryProvider);
    final response = await repo.removeMyStaff(user.id);
    if (!context.mounted) return;

    if (response.success) {
      ref.invalidate(staffListProvider);
      AppSnackBar.success(context, 'Đã gỡ ${user.name} khỏi đội');
    } else {
      AppSnackBar.error(context, response.message);
    }
  }

  Future<void> _toggleActive(
      BuildContext context, UserModel user) async {
    final action = user.isActive ? 'vô hiệu hoá' : 'kích hoạt';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          '${user.isActive ? 'Vô hiệu hoá' : 'Kích hoạt'} tài khoản',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn $action tài khoản của "${user.name}"?',
          style: GoogleFonts.beVietnamPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ',
                style: GoogleFonts.beVietnamPro(color: AppColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  user.isActive ? AppColors.error : AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              user.isActive ? 'Vô hiệu hoá' : 'Kích hoạt',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final result = await ref
        .read(userActionsProvider.notifier)
        .update(user.id, {'isActive': !user.isActive});
    if (!context.mounted) return;

    if (result) {
      AppSnackBar.success(
        context,
        user.isActive ? 'Đã vô hiệu hoá tài khoản' : 'Đã kích hoạt tài khoản',
      );
    } else {
      AppSnackBar.error(context, 'Không thể cập nhật trạng thái');
    }
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final int animIndex;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onToggleActive;
  final VoidCallback? onRemoveStaff;

  const _UserCard({
    required this.user,
    required this.animIndex,
    this.isAdmin = true,
    this.onTap,
    this.onToggleActive,
    this.onRemoveStaff,
  });

  Color get _roleColor => AppHelpers.roleColor(user.role);
  String get _roleLabel => AppHelpers.roleLabel(user.role);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            children: [
              // Avatar
              _Avatar(name: user.name, color: _roleColor,
                  isActive: user.isActive),

              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name.isNotEmpty ? user.name : '-',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: user.isActive
                                  ? AppColors.navy
                                  : AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                                color: _roleColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _roleLabel,
                            style: GoogleFonts.beVietnamPro(
                              color: _roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 12,
                            color: AppColors.muted.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          user.phone.isNotEmpty ? user.phone : '-',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        if (!user.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              'Vô hiệu',
                              style: GoogleFonts.beVietnamPro(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Actions
              if (isAdmin) ...[
                Column(
                  children: [
                    if (onToggleActive != null)
                      GestureDetector(
                        onTap: onToggleActive,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? AppColors.error.withValues(alpha: 0.08)
                                : AppColors.emerald.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            user.isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: user.isActive
                                ? AppColors.error
                                : AppColors.emerald,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.slate,
                      size: 18,
                    ),
                  ],
                ),
              ] else if (onRemoveStaff != null) ...[
                GestureDetector(
                  onTap: onRemoveStaff,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.person_remove_rounded,
                      size: 18,
                      color: AppColors.coral,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(
          delay: Duration(milliseconds: animIndex * 60),
        )
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.04, end: 0, curve: Curves.easeOut);
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final bool isActive;

  const _Avatar(
      {required this.name, required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? color.withValues(alpha: 0.12)
                : AppColors.slateLight,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.beVietnamPro(
                color: isActive ? color : AppColors.slate,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        // Active dot
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isActive ? AppColors.emerald : AppColors.slate,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _UserCardSkeleton extends StatelessWidget {
  const _UserCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.slateLight,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 120, height: 14, color: AppColors.slateLight),
                const SizedBox(height: 6),
                Container(
                    width: 90, height: 12, color: AppColors.slateLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
