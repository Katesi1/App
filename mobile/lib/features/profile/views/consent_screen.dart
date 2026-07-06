import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/account_controller.dart';

/// Quyền đồng ý dữ liệu (`GET/PUT /users/me/consents`). `kyc` server-locked —
/// chỉ toggle được `marketing`.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _saving = false;

  Future<void> _setMarketing(bool value) async {
    setState(() => _saving = true);
    final result = await ref
        .read(accountRepositoryProvider)
        .updateConsents(marketing: value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ref.invalidate(consentsProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final consentsAsync = ref.watch(consentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quyền đồng ý dữ liệu')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(consentsProvider);
          await ref.read(consentsProvider.future);
        },
        child: consentsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorStateWidget(
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(consentsProvider),
          ),
          data: (consent) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  'Bạn có thể quản lý các quyền đồng ý liên quan đến dữ liệu cá nhân. '
                  'Một số quyền là bắt buộc để đảm bảo an toàn nền tảng.',
                  style: TextStyle(color: colors.textSecondary, height: 1.45),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ConsentTile(
                value: consent.kyc,
                enabled: false,
                title: 'Đồng ý xử lý dữ liệu KYC',
                subtitle: 'Bắt buộc để xác thực chủ homestay và chống gian lận',
                icon: Icons.verified_user_outlined,
                onChanged: null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ConsentTile(
                value: consent.marketing,
                enabled: !_saving,
                title: 'Nhận thông tin ưu đãi',
                subtitle: 'Nhận khuyến mãi, tính năng mới và gợi ý dịch vụ',
                icon: Icons.campaign_outlined,
                onChanged: _setMarketing,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Thay đổi được lưu ngay. Quyền KYC do hệ thống quản lý và không thể tắt khi đang dùng dịch vụ.',
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final bool value;
  final bool enabled;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool>? onChanged;

  const _ConsentTile({
    required this.value,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
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
