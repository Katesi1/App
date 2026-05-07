import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class AbuseReportsScreen extends StatelessWidget {
  const AbuseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo vi phạm')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _SummaryCard(),
          SizedBox(height: AppSpacing.md),
          _ReportTile(
            title: 'Tin đăng spam phòng giả',
            reporter: 'user_172',
            level: 'Cao',
            category: 'Spam',
          ),
          _ReportTile(
            title: 'Nội dung không phù hợp',
            reporter: 'user_816',
            level: 'Trung bình',
            category: 'Nội dung',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Text(
        'Hàng đợi này tổng hợp báo cáo vi phạm từ cộng đồng. '
        'Ưu tiên xử lý các ticket mức Cao để giảm rủi ro vận hành.',
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String title;
  final String reporter;
  final String level;
  final String category;

  const _ReportTile({
    required this.title,
    required this.reporter,
    required this.level,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isHigh = level == 'Cao';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reporter: $reporter · Danh mục: $category',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isHigh ? colors.error : colors.warning)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              'Mức độ: $level',
              style: TextStyle(
                color: isHigh ? colors.error : colors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
