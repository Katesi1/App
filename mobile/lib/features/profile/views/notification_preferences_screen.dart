import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/profile_settings_controller.dart';
import '../data/models/notification_preferences.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  NotificationPreferences? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;

    setState(() => _saving = true);
    final (ok, msg) = await ref
        .read(notificationPreferencesActionsProvider.notifier)
        .save(draft);
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
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tùy chọn thông báo')),
      body: prefsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(notificationPreferencesProvider),
        ),
        data: (prefs) {
          _draft ??= prefs;
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
                  'Thông báo vận hành cho chủ homestay và sale: booking, '
                  'thanh toán. Đồng bộ với server.',
                  style: TextStyle(color: colors.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _NotificationTile(
                value: draft.booking,
                title: 'Booking',
                subtitle: 'Xác nhận, huỷ, thay đổi lịch đặt phòng',
                icon: Icons.calendar_month_outlined,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(booking: v)),
              ),
              _NotificationTile(
                value: draft.payment,
                title: 'Thanh toán',
                subtitle: 'Hóa đơn, hoàn tiền, giao dịch subscription',
                icon: Icons.payments_outlined,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(payment: v)),
              ),
              _NotificationTile(
                value: draft.quietHours,
                title: 'Giờ yên lặng',
                subtitle: 'Giảm thông báo từ 22:00 đến 07:00',
                icon: Icons.dark_mode_outlined,
                onChanged: (v) =>
                    setState(() => _draft = draft.copyWith(quietHours: v)),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
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
