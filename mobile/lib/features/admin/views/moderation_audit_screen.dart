import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/moderation_controller.dart';
import '../data/models/moderation_models.dart';

/// Nhật ký kiểm duyệt (`GET /admin/audit-log`). ADMIN-only. Read-only —
/// backend tự ghi log mỗi khi admin thực hiện action.
class ModerationAuditScreen extends ConsumerWidget {
  const ModerationAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final auditAsync = ref.watch(auditLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử kiểm duyệt')),
      body: auditAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(auditLogProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_toggle_off_outlined,
              message: 'Chưa có hoạt động kiểm duyệt nào',
            );
          }
          return RefreshIndicator(
            color: colors.brand,
            onRefresh: () async => ref.invalidate(auditLogProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AuditTile(entry: entries[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final AuditEntry entry;
  const _AuditTile({required this.entry});

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _fmtTime(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year} ${_two(l.hour)}:${_two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitleParts = <String>[
      if (entry.targetLabel != null && entry.targetLabel!.isNotEmpty)
        entry.targetLabel!
      else if (entry.targetType.isNotEmpty)
        entry.targetType,
      if (entry.actorName != null) 'bởi ${entry.actorName}',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.gavel_rounded, size: 18, color: colors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.actionLabel,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.reason != null && entry.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lý do: ${entry.reason}',
                    style:
                        TextStyle(color: colors.textTertiary, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _fmtTime(entry.createdAt),
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
