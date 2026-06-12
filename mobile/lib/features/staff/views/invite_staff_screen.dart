import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/feature_locked.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/staff_controller.dart';
import '../data/models/staff_invite.dart';

/// Trang mời nhân viên — nhập email → tạo lời mời + nhận mã.
///
/// Trước đây là modal bottom sheet; tách thành trang riêng để có không gian
/// rõ ràng hơn. Logic giữ nguyên (validate quyền + slot ở caller trước khi mở,
/// submit + hiện mã ở đây). Pop trả `true` khi tạo thành công để màn quản lý
/// chuyển sang tab "Lời mời".
class InviteStaffScreen extends ConsumerStatefulWidget {
  const InviteStaffScreen({super.key});

  @override
  ConsumerState<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends ConsumerState<InviteStaffScreen> {
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

    final user = ref.read(currentUserProvider);
    if (user == null || !user.canInviteStaff) {
      AppSnackBar.error(
        context,
        user?.staffInviteBlockReason ?? 'Không thể mời nhân viên',
      );
      return;
    }

    setState(() => _submitting = true);

    final (ok, msg, invite) = await ref
        .read(staffActionsProvider.notifier)
        .invite(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok && invite != null) {
      await _showInviteCreatedDialog(context, invite, msg);
      if (!mounted) return;
      context.pop(true);
    } else if (ok) {
      AppSnackBar.success(context, msg);
      context.pop(true);
    } else {
      final err = ref.read(staffActionsProvider).error;
      if (err is ApiFailure && handleFeatureLocked(context, err, user)) {
        return;
      }
      AppSnackBar.error(context, msg);
    }
  }

  Future<void> _showInviteCreatedDialog(
    BuildContext context,
    StaffInvite invite,
    String message,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dColors = dialogContext.colors;
        return AlertDialog(
          title: Text(
            'Đã gửi lời mời',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w700,
              color: dColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: dColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Mã nhân viên (chia sẻ qua chat/SMS):',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: dColors.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.jade50),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        invite.shortCode,
                        style: GoogleFonts.firaCode(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: dColors.brand,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _copyCode(dialogContext, invite.shortCode),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Sao chép mã',
                    ),
                  ],
                ),
              ),
              if (invite.inviteLink != null &&
                  invite.inviteLink!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Email cũng chứa link trực tiếp cho nhân viên.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: dColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppSnackBar.success(context, 'Đã sao chép mã $code');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Mời nhân viên'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded,
                      color: colors.brand, size: 28),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Mời nhân viên',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Nhập email nhân viên — họ sẽ nhận email kèm mã mời để đăng ký.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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
                    backgroundColor: colors.brand,
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
        ),
      ),
    );
  }
}
