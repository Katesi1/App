import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/staff_entitlement.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/subscription_locked_sheet.dart';
import '../../controllers/staff_controller.dart';
import '../../data/models/staff_invite.dart';

/// Mở luồng mời nhân viên qua email: nhập email → BE sinh mã ngẫu nhiên
/// (`HL-XXXXXX`) → hiện mã + liên kết để OWNER copy gửi. Trả về [StaffInvite]
/// vừa tạo (null nếu huỷ/lỗi) để caller chuyển tab / refresh.
Future<StaffInvite?> showInviteStaffFlow(BuildContext context) async {
  final created = await showModalBottomSheet<StaffInvite>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const InviteStaffSheet(),
  );
  if (created != null && context.mounted) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InviteCreatedSheet(invite: created),
    );
  }
  return created;
}

/// Sheet nhập email để mời nhân viên. Pop về [StaffInvite] khi thành công.
class InviteStaffSheet extends ConsumerStatefulWidget {
  const InviteStaffSheet({super.key});

  @override
  ConsumerState<InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends ConsumerState<InviteStaffSheet> {
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

    final notifier = ref.read(staffActionsProvider.notifier);
    final (invite, msg) = await notifier.invite(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _submitting = false);

    if (invite != null) {
      // Trả invite vừa tạo cho màn cha để hiện mã mời (shortCode + link).
      Navigator.pop(context, invite);
    } else {
      // BE 403 subscription.featureLocked → platform-aware sheet.
      if (!SubscriptionLock.maybeHandle(context,
          code: notifier.lastErrorCode, message: msg)) {
        // 409 đầy slot: trên iOS thay copy "nâng cấp" bằng text trung tính.
        AppSnackBar.error(
          context,
          StaffEntitlement.inviteErrorMessage(
            code: notifier.lastErrorCode,
            beMessage: msg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  color: colors.borderDefault,
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
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Nhập email nhân viên — họ sẽ nhận email kèm mã mời để đăng ký.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              enabled: !_submitting,
              style: GoogleFonts.beVietnamPro(color: colors.textPrimary),
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
                backgroundColor: colors.brand,
                foregroundColor: colors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textOnPrimary,
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

/// Hiện sau khi tạo lời mời thành công — show mã mời (`shortCode`) + liên kết
/// để OWNER copy gửi cho nhân viên (nhân viên cũng nhận email kèm link).
class InviteCreatedSheet extends StatelessWidget {
  final StaffInvite invite;
  const InviteCreatedSheet({super.key, required this.invite});

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.success(context, 'Đã sao chép $label');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final hasLink =
        invite.inviteLink != null && invite.inviteLink!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.successBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.check_circle_outline_rounded,
                  size: 28, color: colors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đã tạo lời mời',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Gửi mã mời dưới đây cho ${invite.email}. '
            'Họ cũng đã nhận email kèm liên kết để đăng ký.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CopyField(
            label: 'Mã mời',
            value: invite.shortCode,
            mono: true,
            onCopy: () => _copy(context, invite.shortCode, 'mã mời'),
          ),
          if (hasLink) ...[
            const SizedBox(height: AppSpacing.sm),
            _CopyField(
              label: 'Liên kết',
              value: invite.inviteLink!,
              mono: false,
              onCopy: () => _copy(context, invite.inviteLink!, 'liên kết'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_rounded,
                  size: 13, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Mã hết hạn ${dateFmt.format(invite.expiresAt)}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: colors.brand,
              foregroundColor: colors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }
}

/// Ô hiển thị giá trị (mã mời / liên kết) kèm nút sao chép.
class _CopyField extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final VoidCallback onCopy;

  const _CopyField({
    required this.label,
    required this.value,
    required this.mono,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono
                      ? GoogleFonts.firaCode(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textBrand,
                          letterSpacing: 1,
                        )
                      : GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, size: 18, color: colors.textBrand),
            tooltip: 'Sao chép',
          ),
        ],
      ),
    );
  }
}

/// Danh sách lời mời đang chờ (mã + copy + huỷ). Dùng ở tab "Lời mời".
class InvitesListTab extends ConsumerStatefulWidget {
  const InvitesListTab({super.key});

  @override
  ConsumerState<InvitesListTab> createState() => _InvitesListTabState();
}

class _InvitesListTabState extends ConsumerState<InvitesListTab>
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
    final colors = context.colors;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final canCancel = invite.status == StaffInviteStatus.pending;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderDefault),
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
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(status: invite.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded,
                  size: 14, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                invite.shortCode,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textBrand,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copy(context, invite.shortCode),
                icon: Icon(Icons.copy_rounded,
                    size: 16, color: colors.textSecondary),
                tooltip: 'Sao chép mã',
              ),
              const Spacer(),
              Text(
                'HSD ${dateFmt.format(invite.expiresAt)}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textSecondary,
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
                icon: Icon(Icons.cancel_outlined,
                    size: 16, color: colors.error),
                label: Text(
                  'Huỷ lời mời',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: colors.error,
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
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
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
    final colors = context.colors;
    final (Color bg, Color fg) = switch (status) {
      StaffInviteStatus.pending => (colors.warningBg, colors.warning),
      StaffInviteStatus.accepted => (colors.successBg, colors.success),
      StaffInviteStatus.expired => (
          colors.textTertiary.withValues(alpha: 0.15),
          colors.textTertiary,
        ),
      StaffInviteStatus.cancelled => (colors.errorBg, colors.error),
      StaffInviteStatus.unknown => (
          colors.textTertiary.withValues(alpha: 0.15),
          colors.textTertiary,
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
