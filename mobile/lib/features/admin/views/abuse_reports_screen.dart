import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/moderation_controller.dart';
import '../data/models/moderation_models.dart';

/// Hàng đợi khiếu nại/tranh chấp (`GET /admin/disputes`). ADMIN-only.
class AbuseReportsScreen extends ConsumerWidget {
  const AbuseReportsScreen({super.key});

  static const _filters = <(String?, String)>[
    (null, 'Tất cả'),
    ('pending', 'Chờ xử lý'),
    ('investigating', 'Đang điều tra'),
    ('resolved', 'Đã giải quyết'),
    ('rejected', 'Đã từ chối'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selected = ref.watch(disputeStatusFilterProvider);
    final disputesAsync = ref.watch(disputesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Khiếu nại & vi phạm')),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _filters[i];
                final isSel = value == selected;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSel,
                  onSelected: (_) => ref
                      .read(disputeStatusFilterProvider.notifier)
                      .state = value,
                  selectedColor: colors.brand.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSel ? colors.textBrand : colors.textSecondary,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: disputesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(disputesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.verified_user_outlined,
                    message: 'Không có khiếu nại nào',
                  );
                }
                return RefreshIndicator(
                  color: colors.brand,
                  onRefresh: () async => ref.invalidate(disputesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _DisputeTile(dispute: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  final DisputeModel dispute;
  const _DisputeTile({required this.dispute});

  Color _statusColor(AppColorScheme colors) => switch (dispute.status) {
        'pending' => colors.warning,
        'investigating' => colors.brand,
        'resolved' => colors.success,
        'rejected' => colors.error,
        _ => colors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = _statusColor(colors);
    final meta = [
      if (dispute.propertyName != null) dispute.propertyName!,
      if (dispute.customerName != null) 'Khách: ${dispute.customerName}',
      if (dispute.createdAt != null)
        AppHelpers.vietnameseDayOfWeek(dispute.createdAt!.weekday),
    ].join(' · ');

    return Container(
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
                  dispute.subject,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  dispute.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dispute.description,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Tag(label: dispute.typeLabel, color: colors.brandSecondary),
              if (dispute.amount != null && dispute.amount! > 0) ...[
                const SizedBox(width: 6),
                _Tag(
                  label: AppHelpers.formatPrice(dispute.amount!),
                  color: colors.warning,
                ),
              ],
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meta,
              style: TextStyle(color: colors.textTertiary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
