import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class ModerationAuditScreen extends StatelessWidget {
  const ModerationAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử moderation')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _AuditTile(
            action: 'Khóa user_172',
            reason: 'Spam lặp lại',
            at: '06/05/2026 21:15',
            by: 'admin_01',
          ),
          _AuditTile(
            action: 'Ẩn bài đăng room_548',
            reason: 'Sai sự thật',
            at: '05/05/2026 10:20',
            by: 'moderator_03',
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final String action;
  final String reason;
  final String at;
  final String by;

  const _AuditTile({
    required this.action,
    required this.reason,
    required this.at,
    required this.by,
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
      child: ListTile(
        title: Text(
          action,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('Lý do: $reason\nThực hiện bởi: $by · $at'),
        isThreeLine: true,
        trailing: Icon(Icons.history_toggle_off_outlined, color: colors.brand),
      ),
    );
  }
}
