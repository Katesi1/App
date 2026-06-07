import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/monitoring/analytics_service.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/account_controller.dart';

/// Gửi phản hồi / báo lỗi (`POST /feedback`, rate-limit 10/giờ/user).
class FeedbackReportScreen extends ConsumerStatefulWidget {
  const FeedbackReportScreen({super.key});

  @override
  ConsumerState<FeedbackReportScreen> createState() =>
      _FeedbackReportScreenState();
}

class _FeedbackReportScreenState extends ConsumerState<FeedbackReportScreen> {
  final _contentCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _category = 'bug'; // bug | feature | support | other
  bool _includeDeviceInfo = true;
  bool _sending = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<String?> _deviceInfo() async {
    if (!_includeDeviceInfo) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion} · '
          'app ${info.version}+${info.buildNumber}';
    } catch (_) {
      return Platform.operatingSystem;
    }
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nội dung cần ít nhất 10 ký tự')),
      );
      return;
    }
    setState(() => _sending = true);
    final deviceInfo = await _deviceInfo();
    final result = await ref.read(accountRepositoryProvider).submitFeedback(
          category: _category,
          message: content,
          contact: _contactCtrl.text.trim(),
          deviceInfo: deviceInfo,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.success) {
      AnalyticsService.logEvent('feedback_submitted',
          params: {'category': _category});
      _contentCtrl.clear();
      _contactCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi phản hồi, cảm ơn bạn')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi phản hồi / Báo lỗi')),
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
              'Mô tả càng chi tiết thì đội hỗ trợ xử lý càng nhanh. '
              'Bạn có thể để lại kênh liên hệ để nhận phản hồi.',
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: const [
              DropdownMenuItem(value: 'bug', child: Text('Báo lỗi')),
              DropdownMenuItem(
                  value: 'feature', child: Text('Đề xuất tính năng')),
              DropdownMenuItem(value: 'support', child: Text('Hỗ trợ')),
              DropdownMenuItem(value: 'other', child: Text('Khác')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'bug'),
            decoration: const InputDecoration(labelText: 'Danh mục'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _contactCtrl,
            decoration: const InputDecoration(
              labelText: 'Email/SĐT liên hệ (tuỳ chọn)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _contentCtrl,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Nội dung',
              hintText: 'Mô tả các bước gây lỗi hoặc mong muốn cải thiện...',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _includeDeviceInfo,
            onChanged: (v) => setState(() => _includeDeviceInfo = v ?? true),
            title: const Text('Đính kèm thông tin thiết bị'),
            subtitle: const Text('Giúp kỹ thuật dễ tái hiện lỗi hơn'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: Text(_sending ? 'Đang gửi...' : 'Gửi phản hồi'),
          ),
        ],
      ),
    );
  }
}
