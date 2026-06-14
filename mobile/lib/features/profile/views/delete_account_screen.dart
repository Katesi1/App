import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';

/// Self-delete account flow — required for Apple Guideline 5.1.1(v),
/// GDPR Article 17 (right to erasure), and NĐ 13/2023/NĐ-CP.
/// v1.14: BE không xoá ngay — tạo deletion request grace 30 ngày.
/// Login lại trong grace period → auto-cancel yêu cầu.
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
      final scheduledDeleteAt = _parseScheduledDate(result.data);
      await _showGraceDialog(scheduledDeleteAt);
      if (!mounted) return;
      // Xoá saved credentials (Remember me) để login screen không auto-fill.
      await SecureStorage.clearCredentials();
      // Logout local: clear tokens, FCM unregister, reset state.
      await ref.read(authProvider.notifier).logout();
      // Router tự redirect /login khi authState.isLoggedIn = false.
    } else {
      setState(() => _submitting = false);
      AppSnackBar.error(context, result.message);
    }
  }

  /// Parse ISO string → formatted date "dd/MM/yyyy". Returns null on failure.
  String? _parseScheduledDate(String? iso) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Future<void> _showGraceDialog(String? scheduledDate) async {
    if (!mounted) return;
    final dateText = scheduledDate != null
        ? 'Tài khoản sẽ bị xoá vào ngày $scheduledDate.'
        : 'Tài khoản sẽ bị xoá sau 30 ngày.';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu đã được gửi'),
        content: Text(
          '$dateText\n\n'
          'Bạn có thể đăng nhập lại bất cứ lúc nào trước ngày đó để huỷ '
          'yêu cầu và khôi phục tài khoản.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
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
                      Icon(Icons.schedule_rounded, color: colors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tài khoản sẽ bị xoá sau 30 ngày',
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
                    'Sau khi gửi yêu cầu:\n'
                    '• Bạn sẽ bị đăng xuất ngay lập tức.\n'
                    '• Tài khoản sẽ bị xoá vĩnh viễn sau 30 ngày.\n'
                    '• Đăng nhập lại trong 30 ngày để huỷ yêu cầu '
                    'và khôi phục tài khoản.\n'
                    '• Sau khi xoá: booking, lịch sử thanh toán và '
                    'hồ sơ KYC bị xoá khỏi server (GDPR / NĐ 13).',
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
              onChanged: (v) => setState(() => _confirmedPolicy = v ?? false),
              title: const Text(
                'Tôi hiểu tài khoản sẽ bị xoá sau 30 ngày nếu '
                'tôi không đăng nhập lại để huỷ yêu cầu',
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
        ),
      ),
    );
  }
}
