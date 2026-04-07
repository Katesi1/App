import 'package:flutter/material.dart';
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
import '../../auth/controllers/auth_controller.dart';
import '../controllers/user_controller.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String? _roleFilter; // null = all

  static const _roles = <String?>['ADMIN', 'STAFF'];
  static const _roleLabels = ['Admin', 'Quản lý'];

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider(_roleFilter));
    final user = ref.watch(currentUserProvider);
    final colors = Theme.of(context).colorScheme;
    final userName = user?.name ?? user?.phone ?? '';

    return AppScaffold(
      title: 'Nhân viên',
      selectedIndex: 4,
      showAppBar: false,
      floatingActionButton: Container(
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
          onPressed: () => context.push('/admin/users/new'),
          icon: const Icon(Icons.person_add_rounded, size: 20),
          label: Text(
            'Thêm mới',
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
      ),
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────
          Container(
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
                            'Nhân viên',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quản lý tài khoản hệ thống',
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
                                : 'U',
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
          ),

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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _roleColor => AppHelpers.roleColor(user.role);

  String get _roleLabel => AppHelpers.roleLabel(user.role);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: GoogleFonts.beVietnamPro(
                    color: _roleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
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
                            color: AppColors.navy,
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

                  const SizedBox(height: 3),

                  // Phone + inactive badge
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 12,
                          color: AppColors.muted.withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text(
                        user.phone,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.muted,
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

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.ocean, size: 20),
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
    );
  }
}
