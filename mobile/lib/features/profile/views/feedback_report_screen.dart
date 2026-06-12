import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/monitoring/analytics_service.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/profile_settings_controller.dart';

class FeedbackReportScreen extends ConsumerStatefulWidget {
  const FeedbackReportScreen({super.key});

  @override
  ConsumerState<FeedbackReportScreen> createState() =>
      _FeedbackReportScreenState();
}

class _FeedbackReportScreenState extends ConsumerState<FeedbackReportScreen> {
  final _contentCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _category = 'bug';
  bool _includeDeviceInfo = true;
  bool _submitting = false;

  static const _categories = [
    ('bug', 'Bug'),
    ('feature', 'Đề xuất tính năng'),
    ('support', 'Hỗ trợ'),
  ];

  @override
  void dispose() {
    _contentCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty) {
      AppToast.warning(context, 'Vui lòng nhập nội dung phản hồi');
      return;
    }

    setState(() => _submitting = true);
    final (ok, msg) = await ref.read(feedbackActionsProvider.notifier).submit(
          category: _category,
          content: _contentCtrl.text.trim(),
          contact: _contactCtrl.text.trim().isEmpty
              ? null
              : _contactCtrl.text.trim(),
          includeDeviceInfo: _includeDeviceInfo,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      AppToast.success(context, msg);
    } else {
      AppToast.error(context, msg);
    }

    if (ok) {
      AnalyticsService.logEvent(
        'feedback_submitted',
        params: {'category': _category},
      );
      _contentCtrl.clear();
      _contactCtrl.clear();
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
              'Gửi phản hồi nhanh (tối đa 10 lần/giờ). '
              'Nếu cần theo dõi tiến độ, tạo yêu cầu hỗ trợ.',
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: _categories
                .map(
                  (c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)),
                )
                .toList(),
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
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gửi phản hồi'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile/tickets'),
            icon: const Icon(Icons.confirmation_number_outlined, size: 18),
            label: const Text('Xem yêu cầu hỗ trợ của tôi'),
          ),
        ],
      ),
    );
  }
}
