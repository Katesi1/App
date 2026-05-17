import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu hỗ trợ của tôi')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _OverviewCard(),
          SizedBox(height: AppSpacing.md),
          _TicketTile(
            id: 'HT-1024',
            title: 'Không nhận được thông báo booking',
            status: 'Đang xử lý',
            createdAt: '06/05/2026 20:15',
            priority: 'Cao',
          ),
          _TicketTile(
            id: 'HT-1009',
            title: 'Cập nhật thông tin hóa đơn',
            status: 'Đã giải quyết',
            createdAt: '03/05/2026 14:20',
            priority: 'Trung bình',
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theo dõi tiến độ xử lý',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Mỗi yêu cầu đều có mã ticket và trạng thái xử lý. '
            'Bạn có thể liên hệ lại nếu ticket đã quá hạn.',
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final String createdAt;
  final String priority;

  const _TicketTile({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = status == 'Đã giải quyết';
    final statusColor = isDone ? colors.success : colors.warning;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '$id · $title',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mức ưu tiên: $priority · Tạo lúc: $createdAt',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
