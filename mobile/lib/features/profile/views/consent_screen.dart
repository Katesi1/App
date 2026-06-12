import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/profile_settings_controller.dart';
import '../data/models/user_consents.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  UserConsents? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;

    setState(() => _saving = true);
    final (ok, msg) =
        await ref.read(userConsentsActionsProvider.notifier).save(draft);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      AppSnackBar.success(context, msg);
    } else {
      AppSnackBar.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final consentsAsync = ref.watch(userConsentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quyền đồng ý dữ liệu')),
      body: consentsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(userConsentsProvider),
        ),
        data: (consents) {
          _draft ??= consents;
          final draft = _draft!;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  'Quản lý quyền đồng ý dữ liệu cá nhân. '
                  'Đồng ý KYC được khóa trên server khi đã xác thực.',
                  style: TextStyle(color: colors.textSecondary, height: 1.45),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ConsentTile(
                value: draft.kyc,
                title: 'Đồng ý xử lý dữ liệu KYC',
                subtitle: draft.kycLocked
                    ? 'Đã khóa trên server — không thể tắt sau khi xác thực'
                    : 'Bắt buộc để xác thực chủ homestay',
                icon: Icons.verified_user_outlined,
                enabled: !draft.kycLocked,
                onChanged: draft.kycLocked
                    ? null
                    : (v) => setState(() => _draft = draft.copyWith(kyc: v)),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ConsentTile(
                value: draft.marketing,
                title: 'Nhận thông tin ưu đãi',
                subtitle: 'Khuyến mãi, tính năng mới và gợi ý dịch vụ',
                icon: Icons.campaign_outlined,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(marketing: v)),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const _ConsentTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: colors.brand),
      ),
    );
  }
}
