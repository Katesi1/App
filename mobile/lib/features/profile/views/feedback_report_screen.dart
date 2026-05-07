import 'package:flutter/material.dart';
import '../../../core/monitoring/analytics_service.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class FeedbackReportScreen extends StatefulWidget {
  const FeedbackReportScreen({super.key});

  @override
  State<FeedbackReportScreen> createState() => _FeedbackReportScreenState();
}

class _FeedbackReportScreenState extends State<FeedbackReportScreen> {
  final _contentCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _category = 'Bug';
  bool _includeDeviceInfo = true;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi phản hồi, cảm ơn bạn')),
    );
    AnalyticsService.logEvent(
      'feedback_submitted',
      params: {'category': _category},
    );
    _contentCtrl.clear();
    _contactCtrl.clear();
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
              DropdownMenuItem(value: 'Bug', child: Text('Bug')),
              DropdownMenuItem(
                  value: 'Feature', child: Text('Đề xuất tính năng')),
              DropdownMenuItem(value: 'Support', child: Text('Hỗ trợ')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'Bug'),
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
            onPressed: _submit,
            child: const Text('Gửi yêu cầu hỗ trợ'),
          ),
        ],
      ),
    );
  }
}
