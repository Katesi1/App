import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/account_controller.dart';
import '../data/models/account_models.dart';

/// Tuỳ chọn thông báo (`GET/PUT /users/me/notification-preferences`).
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  NotificationPrefs? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    final result = await ref
        .read(accountRepositoryProvider)
        .updateNotificationPrefs(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ref.invalidate(notificationPrefsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật tùy chọn thông báo')),
      );
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
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tùy chọn thông báo')),
      body: prefsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(notificationPrefsProvider),
        ),
        data: (serverPrefs) {
          final prefs = _draft ?? serverPrefs;
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
                  'Bật/tắt thông báo theo từng nhóm để tránh bỏ lỡ cập nhật quan trọng.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _Tile(
                value: prefs.booking,
                title: 'Booking',
                subtitle: 'Nhận thông báo xác nhận, huỷ, thay đổi lịch đặt',
                icon: Icons.calendar_month_outlined,
                onChanged: (v) =>
                    setState(() => _draft = prefs.copyWith(booking: v)),
              ),
              _Tile(
                value: prefs.payment,
                title: 'Thanh toán',
                subtitle: 'Nhận thông báo hóa đơn, hoàn tiền, giao dịch',
                icon: Icons.payments_outlined,
                onChanged: (v) =>
                    setState(() => _draft = prefs.copyWith(payment: v)),
              ),
              _Tile(
                value: prefs.system,
                title: 'Hệ thống',
                subtitle:
                    'Nhận thông báo bảo trì, cập nhật và bảo mật tài khoản',
                icon: Icons.settings_outlined,
                onChanged: (v) =>
                    setState(() => _draft = prefs.copyWith(system: v)),
              ),
              _Tile(
                value: prefs.quietHours,
                title: 'Giờ yên lặng',
                subtitle:
                    'Giảm thông báo từ ${prefs.quietFrom} đến ${prefs.quietTo}',
                icon: Icons.dark_mode_outlined,
                onChanged: (v) =>
                    setState(() => _draft = prefs.copyWith(quietHours: v)),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu...' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _Tile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: colors.brand),
      ),
    );
  }
}
