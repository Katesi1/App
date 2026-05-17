import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  static const _bookingKey = 'notify_booking';
  static const _paymentKey = 'notify_payment';
  static const _systemKey = 'notify_system';
  static const _quietHoursKey = 'notify_quiet_hours';
  bool _booking = true;
  bool _payment = true;
  bool _system = true;
  bool _quietHours = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _booking = prefs.getBool(_bookingKey) ?? true;
      _payment = prefs.getBool(_paymentKey) ?? true;
      _system = prefs.getBool(_systemKey) ?? true;
      _quietHours = prefs.getBool(_quietHoursKey) ?? false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bookingKey, _booking);
    await prefs.setBool(_paymentKey, _payment);
    await prefs.setBool(_systemKey, _system);
    await prefs.setBool(_quietHoursKey, _quietHours);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật tùy chọn thông báo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Tùy chọn thông báo')),
      body: ListView(
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
          _NotificationTile(
            value: _booking,
            title: 'Booking',
            subtitle: 'Nhận thông báo xác nhận, huỷ, thay đổi lịch đặt',
            icon: Icons.calendar_month_outlined,
            onChanged: (v) => setState(() => _booking = v),
          ),
          _NotificationTile(
            value: _payment,
            title: 'Thanh toán',
            subtitle: 'Nhận thông báo hóa đơn, hoàn tiền, giao dịch',
            icon: Icons.payments_outlined,
            onChanged: (v) => setState(() => _payment = v),
          ),
          _NotificationTile(
            value: _system,
            title: 'Hệ thống',
            subtitle: 'Nhận thông báo bảo trì, cập nhật và bảo mật tài khoản',
            icon: Icons.settings_outlined,
            onChanged: (v) => setState(() => _system = v),
          ),
          _NotificationTile(
            value: _quietHours,
            title: 'Giờ yên lặng',
            subtitle: 'Giảm thông báo từ 22:00 đến 07:00',
            icon: Icons.dark_mode_outlined,
            onChanged: (v) => setState(() => _quietHours = v),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _save,
            child: const Text('Lưu'),
          ),
        ],
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
