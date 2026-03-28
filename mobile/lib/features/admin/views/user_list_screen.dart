import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/user_controller.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String? _roleFilter; // null = all

  static const _roles = <String?>['ADMIN', 'OWNER', 'SALE'];
  static const _roleLabels = ['Admin', 'Chủ nhà', 'Sale'];

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider(_roleFilter));
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Nhân viên',
      selectedIndex: 4,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/users/new'),
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Thêm mới',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Role filter chips ─────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              children: [
                // All chip
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
                ...List.generate(_roles.length, (i) {
                  final role = _roles[i];
                  final color = AppHelpers.roleColor(role);
                  final selected = _roleFilter == role;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(_roleLabels[i]),
                      selected: selected,
                      onSelected: (_) => setState(() => _roleFilter = role),
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
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () =>
                  SkeletonList(skeleton: const UserCardSkeleton(), count: 6),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(userListProvider),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline_rounded,
                    message: _roleFilter == null
                        ? 'Chưa có nhân viên nào'
                        : 'Không có ${AppHelpers.roleLabel(_roleFilter)} nào',
                    onAction: () => context.push('/admin/users/new'),
                    actionLabel: 'Thêm mới',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(userListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _UserCard(
                      user: users[i],
                      index: i,
                      onEdit: () =>
                          context.push('/admin/users/${users[i].id}/edit'),
                      onDelete: () => _deleteUser(context, ref, users[i]),
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

  Future<void> _deleteUser(
      BuildContext context, WidgetRef ref, UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Vô hiệu hoá tài khoản',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        content: Text('Vô hiệu hoá tài khoản "${user.name}"?',
            style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vô hiệu hoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final result = await UserRepository().deleteUser(user.id);
    if (!context.mounted) return;
    if (result.success) {
      ref.invalidate(userListProvider);
      AppSnackBar.success(context, 'Đã vô hiệu hoá tài khoản');
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

}

// ─── User Card ────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _roleColor => AppHelpers.roleColor(user.role);

  String get _roleLabel => AppHelpers.roleLabel(user.role);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor.withValues(alpha: 0.12),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: GoogleFonts.beVietnamPro(
                  color: _roleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + role
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
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

                  const SizedBox(height: 2),

                  // Phone
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 12,
                          color: colors.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 3),
                      Text(
                        user.phone,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),

                      // Inactive badge
                      if (!user.isActive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
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

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: colors.primary, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Chỉnh sửa',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.block_rounded,
                      color: AppColors.error, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Vô hiệu hoá',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.05, end: 0);
  }
}
