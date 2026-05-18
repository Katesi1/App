import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/staff_controller.dart';
import '../data/models/staff_invite.dart';

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

  Future<void> _openInviteSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _InviteStaffSheet(),
    );
    if (created == true && mounted) {
      _tabCtrl.animateTo(1); // switch to "Invites" tab
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quản lý nhân viên',
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.ocean,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.ocean,
              labelStyle: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Nhân viên'),
                Tab(text: 'Lời mời'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openInviteSheet,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Mời nhân viên'),
        backgroundColor: AppColors.ocean,
      ),
    );
  }
}

// Tab: active staff.

class _StaffListTab extends ConsumerStatefulWidget {
  const _StaffListTab();

  @override
  ConsumerState<_StaffListTab> createState() => _StaffListTabState();
}

class _StaffListTabState extends ConsumerState<_StaffListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                onRemove: () => _confirmRemove(context, ref, user.id, user.name),
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
      builder: (_) => AlertDialog(
        title: const Text('Xoá nhân viên?'),
        content: Text(
            'Nhân viên "$name" sẽ bị vô hiệu hoá. Bạn có thể mời lại sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ocean.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.ocean),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.coral),
            tooltip: 'Xoá nhân viên',
          ),
        ],
      ),
    );
  }
}

// Tab: invites.

class _InvitesListTab extends ConsumerStatefulWidget {
  const _InvitesListTab();

  @override
  ConsumerState<_InvitesListTab> createState() => _InvitesListTabState();
}

class _InvitesListTabState extends ConsumerState<_InvitesListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
    final dateFmt = DateFormat('dd/MM/yyyy');
    final canCancel = invite.status == StaffInviteStatus.pending;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invite.email,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              _StatusBadge(status: invite.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                invite.shortCode,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ocean,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copy(context, invite.shortCode),
                icon: const Icon(Icons.copy_rounded,
                    size: 16, color: AppColors.muted),
                tooltip: 'Sao chép mã',
              ),
              const Spacer(),
              Text(
                'HSD ${dateFmt.format(invite.expiresAt)}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmCancel(context, ref),
                icon: const Icon(Icons.cancel_outlined,
                    size: 16, color: AppColors.coral),
                label: Text(
                  'Huỷ lời mời',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.coral,
                  ),
                ),
              ),
            ),
          ],
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
      builder: (_) => AlertDialog(
        title: const Text('Huỷ lời mời?'),
        content: Text('Lời mời tới ${invite.email} sẽ bị huỷ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
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

class _StatusBadge extends StatelessWidget {
  final StaffInviteStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      StaffInviteStatus.pending => (
          AppColors.amber.withValues(alpha: 0.15),
          AppColors.amber,
        ),
      StaffInviteStatus.accepted => (
          AppColors.emerald.withValues(alpha: 0.15),
          AppColors.emerald,
        ),
      StaffInviteStatus.expired => (
          AppColors.muted.withValues(alpha: 0.15),
          AppColors.muted,
        ),
      StaffInviteStatus.cancelled => (
          AppColors.coral.withValues(alpha: 0.15),
          AppColors.coral,
        ),
      StaffInviteStatus.unknown => (
          AppColors.muted.withValues(alpha: 0.15),
          AppColors.muted,
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

// Bottom sheet: enter invite email.

class _InviteStaffSheet extends ConsumerStatefulWidget {
  const _InviteStaffSheet();

  @override
  ConsumerState<_InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends ConsumerState<_InviteStaffSheet> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final (ok, msg) = await ref
        .read(staffActionsProvider.notifier)
        .invite(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      AppSnackBar.success(context, msg);
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mời nhân viên',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Nhập email nhân viên — họ sẽ nhận email kèm mã mời để đăng ký.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Email nhân viên',
                hintText: 'nv1@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Vui lòng nhập email';
                final emailReg = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                if (!emailReg.hasMatch(value)) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ocean,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Gửi lời mời'),
            ),
          ],
        ),
      ),
    );
  }
}
