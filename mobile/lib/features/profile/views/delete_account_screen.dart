import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';

/// Self-delete account flow — required for Apple Guideline 5.1.1(v) and
/// GDPR Article 17 (right to erasure).
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
      // Logout local: clear tokens, FCM unregister, reset state.
      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;
      AppSnackBar.success(context, result.message);
      // Router redirects to /login automatically when authState.isLoggedIn = false.
    } else {
      setState(() => _submitting = false);
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canDelete = _confirmCtrl.text.trim().toUpperCase() == 'XOA';

    return Scaffold(
      appBar: AppBar(title: const Text('Xoá tài khoản')),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.errorBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: colors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Hành động này không thể hoàn tác',
                          style: TextStyle(
                            color: colors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sau khi xoá tài khoản:\n'
                    '• Booking + lịch sử thanh toán bị mất quyền truy cập.\n'
                    '• Hồ sơ KYC + ảnh CCCD bị xoá khỏi server (theo GDPR).\n'
                    '• Subscription đang chạy bị huỷ — không hoàn tiền '
                    'cho phần còn lại.\n'
                    '• Email của bạn không thể đăng ký lại trong 30 ngày.',
                    style: TextStyle(color: colors.error, height: 1.45),
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
              onChanged: (v) =>
                  setState(() => _confirmedPolicy = v ?? false),
              title: const Text(
                'Tôi hiểu rằng dữ liệu KHÔNG thể khôi phục được sau khi xoá',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: canDelete && _confirmedPolicy && !_submitting
                  ? _submit
                  : null,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Xoá tài khoản vĩnh viễn'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _submitting ? null : () => context.pop(),
                child: const Text('Huỷ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
