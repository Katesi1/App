import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/staff_entitlement.dart';
import '../../../core/utils/subscription_gating.dart';
import '../../../data/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../verify/controllers/verify_flow_controller.dart';
import '../../verify/data/models/verify_enums.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/staff_controller.dart';
import '../data/models/staff_invite.dart';
import '../widgets/staff_invite_plan_banner.dart';
import '../../../shared/widgets/subscription_status_banner.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onUpgradeFabTapped(UserModel user) {
    final verifyStatus = ref.read(verifyFlowControllerProvider).status;
    if (verifyStatus == VerifyStatus.paymentPending) {
      AppToast.show(
        context,
        message:
            'Bạn đang có thanh toán chờ xử lý. Hoàn tất trước khi mua gói mới.',
        type: AppToastType.warning,
        actionLabel: 'Xem đơn →',
        onAction: () => context.push('/verify/payment'),
      );
      return;
    }
    final slots = StaffEntitlement.maxSlotsForPlanId(user.subscriptionPlanId);
    AppToast.show(
      context,
      message: slots == 0
          ? 'Để mời nhân viên, bạn cần tối thiểu gói ${StaffEntitlement.minPlanLabel}.'
          : user.staffInviteBlockReason,
      type: AppToastType.info,
      actionLabel: 'Nâng cấp ngay →',
      onAction: () => context.push(user.subscriptionPlanPickerRoute),
    );
  }

  Future<void> _openInviteSheet() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (!user.canInviteStaff) {
      AppSnackBar.info(context, user.staffInviteBlockReason);
      return;
    }

    final limitMsg = await _staffInviteLimitMessage(user);
    if (!mounted) return;
    if (limitMsg != null) {
      AppSnackBar.error(context, limitMsg);
      return;
    }

    // Mở trang mời nhân viên (thay cho modal). Pop trả `true` khi tạo thành công.
    final created = await context.push<bool>('/staff/manage/invite');
    if (created == true && mounted) {
      _tabCtrl.animateTo(1); // chuyển sang tab "Lời mời"
    }
  }

  /// Trả message nếu đã hết slot theo gói (Starter/Standard = 3).
  Future<String?> _staffInviteLimitMessage(UserModel user) async {
    final max = user.maxStaffInviteSlots;
    if (max == null) return null;

    final staff = await ref.read(staffListProvider.future);
    final invites = await ref.read(staffInvitesProvider.future);
    final pendingInvites = invites
        .where(
          (i) => i.status == StaffInviteStatus.pending && !i.isExpired,
        )
        .length;
    final used = staff.length + pendingInvites;
    if (used >= max) {
      return user.staffInviteAtLimitMessage(used);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final canInvite = user?.canInviteStaff ?? false;
    // Chỉ hiện FAB "Nâng cấp gói" khi bị chặn do GÓI (chưa có gói / Mini).
    // Đã có gói (trial/active) bị chặn do KYC → ẩn FAB, banner lo CTA xác minh.
    final blockedByPlan = user != null &&
        SubscriptionGating.staffInviteBlock(user) == StaffInviteBlock.plan;

    return AppScaffold(
      title: 'Quản lý nhân viên',
      showBottomNav: false,
      customAppBar: AppBar(title: const Text('Quản lý nhân viên')),
      body: Column(
        children: [
          if (user != null) ...[
            SubscriptionStatusBanner(user: user),
            StaffInvitePlanBanner(user: user),
            if (user.canInviteStaff && user.maxStaffInviteSlots != null)
              _StaffSlotUsageBanner(user: user),
          ],
          Container(
            color: colors.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: colors.brand,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.brand,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              dividerColor: colors.borderSubtle,
              labelStyle: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  height: 46,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Nhân viên'),
                    ],
                  ),
                ),
                Tab(
                  height: 46,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Lời mời'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _StaffListTab(),
                _InvitesListTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: user != null && user.isSubscriptionFrozen
          ? null
          : canInvite
              ? FloatingActionButton.extended(
                  onPressed: _openInviteSheet,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Mời nhân viên'),
                  backgroundColor: colors.brand,
                )
              : blockedByPlan
                  ? FloatingActionButton.extended(
                      onPressed: () => _onUpgradeFabTapped(user),
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Nâng cấp gói'),
                      backgroundColor: AppColors.slate400,
                    )
                  : null,
    );
  }
}

class _StaffSlotUsageBanner extends ConsumerWidget {
  final UserModel user;
  const _StaffSlotUsageBanner({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    final invitesAsync = ref.watch(staffInvitesProvider);

    return staffAsync.when(
      data: (staff) {
        final pending = invitesAsync.whenOrNull(
              data: (invites) => invites
                  .where(
                    (i) =>
                        i.status == StaffInviteStatus.pending && !i.isExpired,
                  )
                  .length,
            ) ??
            0;
        return StaffSlotUsageChip(
          used: staff.length + pending,
          max: user.maxStaffInviteSlots,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Tab: Nhân viên đang active ────────────────────────────────────────────────

class _StaffListTab extends ConsumerWidget {
  const _StaffListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(staffListProvider),
      child: staffAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(staffListProvider),
        ),
        data: (staff) {
          if (staff.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.badge_outlined,
              message: 'Chưa có nhân viên nào',
              subMessage:
                  'Bấm "Mời nhân viên" để gửi lời mời qua email cho nhân viên của bạn.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final user = staff[i];
              return _StaffTile(
                name: user.name.isEmpty ? user.email ?? 'Nhân viên' : user.name,
                email: user.email ?? '',
                phone: user.phone,
                onRemove: () =>
                    _confirmRemove(context, ref, user.id, user.name),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá nhân viên?'),
        content: Text(
            'Nhân viên "$name" sẽ bị vô hiệu hoá. Bạn có thể mời lại sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: dialogContext.colors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final (ok, msg) =
        await ref.read(staffActionsProvider.notifier).removeStaff(userId);
    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.success(context, msg);
    } else {
      AppSnackBar.error(context, msg);
    }
  }
}

class _StaffTile extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final VoidCallback onRemove;

  const _StaffTile({
    required this.name,
    required this.email,
    required this.phone,
    required this.onRemove,
  });

  String get _initial {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    return source.isEmpty ? '?' : source.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.brand.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar gradient + chữ cái đầu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.brand, colors.brandLight],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors.brand.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initial,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Nhân viên',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.brand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _IconLine(
                  icon: Icons.email_outlined,
                  text: email,
                  colors: colors,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _IconLine(
                    icon: Icons.phone_outlined,
                    text: phone,
                    colors: colors,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Đang hoạt động',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            style: IconButton.styleFrom(
              backgroundColor: colors.error.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(8),
            ),
            icon: Icon(Icons.delete_outline_rounded,
                color: colors.error, size: 20),
            tooltip: 'Xoá nhân viên',
          ),
        ],
      ),
    );
  }
}

/// Dòng icon + text (email/phone) dùng chung trong staff tile.
class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppColorScheme colors;

  const _IconLine({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: colors.textTertiary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab: Lời mời ──────────────────────────────────────────────────────────────

class _InvitesListTab extends ConsumerWidget {
  const _InvitesListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(staffInvitesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(staffInvitesProvider),
      child: invitesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(staffInvitesProvider),
        ),
        data: (invites) {
          if (invites.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.mail_outline_rounded,
              message: 'Chưa có lời mời nào',
              subMessage: 'Lời mời bạn gửi sẽ hiển thị ở đây.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: invites.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _InviteTile(invite: invites[i]),
          );
        },
      ),
    );
  }
}

class _InviteTile extends ConsumerWidget {
  final StaffInvite invite;
  const _InviteTile({required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final canCancel = invite.status == StaffInviteStatus.pending;
    final showCode = invite.shortCode.isNotEmpty &&
        invite.status == StaffInviteStatus.pending;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.brand.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.mark_email_unread_outlined,
                    size: 18, color: colors.brand),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  invite.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _StatusBadge(status: invite.status),
            ],
          ),
          if (showCode) ...[
            const SizedBox(height: AppSpacing.md),
            _CodeTicket(
              code: invite.shortCode,
              onCopy: () => _copy(context, invite.shortCode),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 13, color: colors.textTertiary),
              const SizedBox(width: 5),
              Text(
                'Hết hạn ${dateFmt.format(invite.expiresAt)}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11.5,
                  color: colors.textSecondary,
                ),
              ),
              if (canCancel) ...[
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _confirmCancel(context, ref),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.cancel_outlined,
                      size: 15, color: colors.error),
                  label: Text(
                    'Huỷ lời mời',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.success(context, 'Đã sao chép $text');
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Huỷ lời mời?'),
        content: Text('Lời mời tới ${invite.email} sẽ bị huỷ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: dialogContext.colors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Huỷ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final (ok, msg) =
        await ref.read(staffActionsProvider.notifier).cancelInvite(invite.id);
    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.success(context, msg);
    } else {
      AppSnackBar.error(context, msg);
    }
  }
}

/// Khối mã mời dạng "vé" — nền tint brand, mã monospace nổi bật + nút sao chép.
class _CodeTicket extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;

  const _CodeTicket({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.brand.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2_rounded, size: 20, color: colors.brand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MÃ NHÂN VIÊN',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  code,
                  style: GoogleFonts.firaCode(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.brand,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: colors.brand.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(8),
            ),
            icon: Icon(Icons.copy_rounded, size: 16, color: colors.brand),
            tooltip: 'Sao chép mã',
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final StaffInviteStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color bg, Color fg) = switch (status) {
      StaffInviteStatus.pending => (
          colors.warning.withValues(alpha: 0.15),
          colors.warning,
        ),
      StaffInviteStatus.accepted => (
          colors.success.withValues(alpha: 0.15),
          colors.success,
        ),
      StaffInviteStatus.expired => (
          colors.textSecondary.withValues(alpha: 0.15),
          colors.textSecondary,
        ),
      StaffInviteStatus.cancelled => (
          colors.error.withValues(alpha: 0.15),
          colors.error,
        ),
      StaffInviteStatus.unknown => (
          colors.textSecondary.withValues(alpha: 0.15),
          colors.textSecondary,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
