import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/staff_entitlement.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/staff_upsell_view.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/user_controller.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  // null = all staff (OWNER + SALE, excludes ADMIN).
  int? _roleFilter;

  // 1=OWNER, 2=SALE
  static const _filterRoles = [2, 1];
  static const _filterLabels = ['Sale', 'Chủ nhà'];

  /// OWNER's add-staff eligibility — mirrors backend `StaffEntitlement` so a
  /// nick without KYC/plan sees an upsell instead of an add button. ADMIN
  /// always passes (bypass inside [StaffEntitlement.evaluate]).
  InviteEligibility _eligibility(UserModel? user) {
    final staff = ref.watch(staffListProvider).valueOrNull;
    final used = staff?.where((u) => !u.isAdmin).length ?? 0;
    return StaffEntitlement.evaluate(
      isAdmin: user?.isAdmin ?? false,
      isOwner: user?.isOwner ?? false,
      isKycApproved: user?.isKycApproved ?? false,
      subscriptionStatus: user?.subscriptionStatus ?? 'none',
      planId: user?.subscriptionPlanId,
      usedSlots: used,
      enforceSlotLimit: staff != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.isAdmin ?? false;

    final eligibility = _eligibility(currentUser);
    final blocked = !eligibility.allowed;

    final usersAsync = ref.watch(staffListProvider);

    return AppScaffold(
      title: isAdmin ? 'Quản lý nhân viên' : 'Nhân viên của tôi',
      showBottomNav: false,
      customAppBar: _buildAppBar(context, isAdmin),
      floatingActionButton: blocked ? null : _buildFab(context, isAdmin),
      // Blocked OWNER (no KYC / no plan / Mini) → upsell instead of the list.
      body: blocked
          ? StaffUpsellView(eligibility: eligibility, user: currentUser)
          : Column(
              children: [
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
                      onRetry: () => ref.invalidate(staffListProvider),
                    ),
                    data: (allUsers) {
                      // Exclude Admin from management list.
                      final users = allUsers
                          .where((u) => !u.isAdmin)
                          .where((u) =>
                              _roleFilter == null || u.role == _roleFilter)
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
                          actionLabel:
                              isAdmin ? 'Thêm nhân viên' : 'Thêm vào đội',
                        );
                      }

                      return RefreshIndicator(
                        color: colors.brand,
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

  /// Minimal app bar (back + title) — replaces the old gradient header; the
  /// bottom nav is hidden on this screen for a focused sub-page feel.
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isAdmin) {
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.bgSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go(isAdmin ? '/admin' : '/dashboard'),
      ),
      title: Text(
        isAdmin ? 'Quản lý nhân viên' : 'Nhân viên của tôi',
        style: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final colors = context.colors;
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
              selectedColor: colors.brand.withValues(alpha: 0.15),
              checkmarkColor: colors.brand,
              labelStyle: GoogleFonts.beVietnamPro(
                fontWeight:
                    _roleFilter == null ? FontWeight.w700 : FontWeight.w500,
                color: _roleFilter == null ? colors.brand : colors.textPrimary,
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
                onSelected: (_) => setState(() => _roleFilter = role),
                selectedColor: color.withValues(alpha: 0.15),
                checkmarkColor: color,
                labelStyle: GoogleFonts.beVietnamPro(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : colors.textPrimary,
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
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colors.brandLight, colors.brand],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.brand.withValues(alpha: 0.35),
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

  /// OWNER views unassigned SALE list → tap to add to team.
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
      builder: (ctx) {
        final colors = ctx.colors;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: const BorderRadius.vertical(
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
                    color: colors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded,
                        color: colors.brand, size: 22),
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
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${available.length} nhân viên có thể thêm',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.borderDefault),
              // List
              if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 48, color: colors.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'Không có nhân viên nào sẵn sàng',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhân viên cần đăng ký tài khoản trước',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: colors.textTertiary,
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
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colors.borderDefault,
                      indent: 68,
                    ),
                    itemBuilder: (_, i) {
                      final sale = available[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.brand.withValues(alpha: 0.12),
                          child: Text(
                            sale.name.isNotEmpty
                                ? sale.name[0].toUpperCase()
                                : 'S',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          sale.name.isNotEmpty ? sale.name : 'Chưa đặt tên',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          sale.email ?? sale.phone,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: colors.textSecondary,
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
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
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
        );
      },
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

  /// OWNER removes staff from team.
  Future<void> _removeStaff(BuildContext context, UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
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
                  style: GoogleFonts.beVietnamPro(color: colors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
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
        );
      },
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

  Future<void> _toggleActive(BuildContext context, UserModel user) async {
    final action = user.isActive ? 'vô hiệu hoá' : 'kích hoạt';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
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
                  style: GoogleFonts.beVietnamPro(color: colors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: user.isActive ? colors.error : colors.success,
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
        );
      },
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

  (String, Color, Color) _saleMembershipTag(BuildContext context) {
    final colors = context.colors;
    return switch (user.saleMembershipState) {
      'invited' => ('Chờ kích hoạt', colors.warning, colors.warningBg),
      'suspended' => ('Tạm khoá', colors.error, colors.errorBg),
      'unassigned' => (
          'Chưa gán owner',
          colors.textSecondary,
          colors.bgSurfaceContainer
        ),
      _ => ('Đang hoạt động', colors.success, colors.successBg),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDefault),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            children: [
              // Avatar
              _Avatar(
                  name: user.name, color: _roleColor, isActive: user.isActive),

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
                                  ? colors.textPrimary
                                  : colors.textSecondary,
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
                        if (user.isSale) ...[
                          const SizedBox(width: 6),
                          Builder(builder: (context) {
                            final (label, textColor, bgColor) =
                                _saleMembershipTag(context);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.beVietnamPro(
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 12,
                            color: colors.textSecondary.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          user.phone.isNotEmpty ? user.phone : '-',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (!user.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.errorBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              'Vô hiệu',
                              style: GoogleFonts.beVietnamPro(
                                color: colors.error,
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
                                ? colors.errorBg
                                : colors.successBg,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            user.isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color:
                                user.isActive ? colors.error : colors.success,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textTertiary,
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
                      color: colors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.person_remove_rounded,
                      size: 18,
                      color: colors.error,
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
    final colors = context.colors;
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? color.withValues(alpha: 0.12)
                : colors.bgSurfaceContainer,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.beVietnamPro(
                color: isActive ? color : colors.textTertiary,
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
              color: isActive ? colors.success : colors.textTertiary,
              border: Border.all(color: colors.bgSurface, width: 2),
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
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.bgSurfaceContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 120, height: 14, color: colors.bgSurfaceContainer),
                const SizedBox(height: 6),
                Container(
                    width: 90, height: 12, color: colors.bgSurfaceContainer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
