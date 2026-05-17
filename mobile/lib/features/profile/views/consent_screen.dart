import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  static const _kycConsentKey = 'consent_kyc';
  static const _marketingConsentKey = 'consent_marketing';
  bool _kycConsent = true;
  bool _marketingConsent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _kycConsent = prefs.getBool(_kycConsentKey) ?? true;
      _marketingConsent = prefs.getBool(_marketingConsentKey) ?? false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kycConsentKey, _kycConsent);
    await prefs.setBool(_marketingConsentKey, _marketingConsent);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu quyền đồng ý')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền đồng ý dữ liệu')),
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
              'Bạn có thể quản lý các quyền đồng ý liên quan đến dữ liệu cá nhân. '
              'Một số quyền là bắt buộc để đảm bảo an toàn nền tảng.',
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ConsentTile(
            value: _kycConsent,
            title: 'Đồng ý xử lý dữ liệu KYC',
            subtitle: 'Bắt buộc để xác thực chủ homestay và chống gian lận',
            icon: Icons.verified_user_outlined,
            onChanged: (v) => setState(() => _kycConsent = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConsentTile(
            value: _marketingConsent,
            title: 'Nhận thông tin ưu đãi',
            subtitle: 'Nhận khuyến mãi, tính năng mới và gợi ý dịch vụ',
            icon: Icons.campaign_outlined,
            onChanged: (v) => setState(() => _marketingConsent = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _save,
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _ConsentTile({
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
      padding: const EdgeInsets.all(AppSpacing.sm),
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
