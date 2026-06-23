import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/models/account_deletion_schedule.dart';

/// Self-delete account flow — compliance Apple Guideline 5.1.1(v) +
/// Google Play User Data + GDPR Article 17 + NĐ 13/2023 (grace 30 ngày).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _confirmedPolicy = false;
  bool _submitting = false;

  /// Khi != null → request đã gửi thành công, hiển thị màn xác nhận grace.
  AccountDeletionSchedule? _schedule;
  bool _scheduleSubmitted = false;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final result = await UserRepository().deleteMyAccount(
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      // Không logout ngay — hiển thị màn xác nhận với ngày xoá để user biết
      // có thể đăng nhập lại huỷ yêu cầu. Logout khi user bấm "Đăng xuất".
      setState(() {
        _submitting = false;
        _scheduleSubmitted = true;
        _schedule = result.data;
      });
    } else {
      setState(() => _submitting = false);
      AppSnackBar.error(context, result.message);
    }
  }

  Future<void> _logoutAfterRequest() async {
    setState(() => _submitting = true);
    // Logout local: clear tokens, FCM unregister, reset state.
    await ref.read(authProvider.notifier).logout();
    // Router redirect /login tự động khi authState.isLoggedIn = false.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xoá tài khoản')),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: _scheduleSubmitted
            ? _buildSuccessView(context)
            : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    final canDelete = _confirmCtrl.text.trim().toUpperCase() == 'XOA';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.warningBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: colors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tài khoản sẽ bị xoá sau 30 ngày',
                      style: TextStyle(
                        color: colors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Khi bạn gửi yêu cầu xoá:\n'
                '• Tài khoản bị khoá và lên lịch xoá sau 30 ngày.\n'
                '• Đăng nhập lại trong 30 ngày để huỷ yêu cầu và khôi '
                'phục tài khoản như cũ.\n'
                '• Sau 30 ngày: booking, lịch sử thanh toán, hồ sơ KYC + '
                'ảnh CCCD bị xoá vĩnh viễn (theo NĐ 13 & GDPR).\n'
                '• Subscription đang chạy bị huỷ — không hoàn tiền cho '
                'phần còn lại.',
                style: TextStyle(color: colors.textPrimary, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Lý do xoá (tuỳ chọn — giúp chúng tôi cải thiện)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _reasonCtrl,
          maxLength: 200,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Vd: Không còn dùng app, lo ngại bảo mật...',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Nhập "XOA" để xác nhận',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _confirmCtrl,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Xác nhận',
            hintText: 'XOA',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _confirmedPolicy,
          onChanged: (v) => setState(() => _confirmedPolicy = v ?? false),
          title: const Text(
            'Tôi hiểu tài khoản sẽ bị xoá sau 30 ngày và có thể đăng nhập '
            'lại trong thời gian này để huỷ yêu cầu',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed:
              canDelete && _confirmedPolicy && !_submitting ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Gửi yêu cầu xoá tài khoản'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: _submitting ? null : () => context.pop(),
            child: const Text('Huỷ'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final colors = context.colors;
    final schedule = _schedule;
    final deleteDateText = schedule != null
        ? DateFormat('dd/MM/yyyy').format(schedule.scheduledDeleteAt.toLocal())
        : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(Icons.schedule_send_rounded, size: 56, color: colors.warning),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Đã gửi yêu cầu xoá tài khoản',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.warningBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            deleteDateText != null
                ? 'Tài khoản sẽ bị xoá vào ngày $deleteDateText. Bạn có thể '
                    'đăng nhập lại bất cứ lúc nào trước ngày này để huỷ yêu '
                    'cầu và khôi phục tài khoản.'
                : 'Tài khoản sẽ bị xoá sau 30 ngày. Bạn có thể đăng nhập lại '
                    'bất cứ lúc nào trong thời gian này để huỷ yêu cầu và '
                    'khôi phục tài khoản.',
            style: TextStyle(color: colors.textPrimary, height: 1.45),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _submitting ? null : _logoutAfterRequest,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Đăng xuất'),
        ),
      ],
    );
  }
}
