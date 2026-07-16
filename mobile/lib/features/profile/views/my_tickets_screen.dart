import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/profile_settings_controller.dart';
import '../data/models/support_ticket.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu hỗ trợ của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tạo yêu cầu'),
      ),
      body: ticketsAsync.when(
        loading: () => const SkeletonList(skeleton: UserCardSkeleton()),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(supportTicketListProvider),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.support_agent_outlined,
              message: 'Chưa có yêu cầu hỗ trợ',
              actionLabel: 'Tạo yêu cầu đầu tiên',
              onAction: () => _showCreateSheet(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supportTicketListProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                88,
              ),
              children: [
                const _OverviewCard(),
                const SizedBox(height: AppSpacing.md),
                ...tickets.map(
                  (t) => _TicketTile(
                    ticket: t,
                    onTap: () => context.push('/profile/tickets/${t.id}'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateTicketSheet(
        onCreated: (id) {
          Navigator.of(ctx).pop();
          context.push('/profile/tickets/$id');
        },
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
      child: Text(
        'Mỗi yêu cầu có mã ticket và trạng thái xử lý. '
        'Bạn có thể trả lời thêm trong chi tiết ticket.',
        style: TextStyle(color: colors.textSecondary, height: 1.45),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _TicketTile({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = ticket.status.toLowerCase() == 'resolved' ||
        ticket.status.toLowerCase() == 'closed';
    final statusColor = isDone ? colors.success : colors.warning;
    final created = ticket.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(ticket.createdAt!.toLocal())
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
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
                        '${ticket.displayCode} · ${ticket.subject}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        ticket.statusLabel,
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
                  'Tạo lúc: $created',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTicketSheet extends ConsumerStatefulWidget {
  final ValueChanged<String> onCreated;

  const _CreateTicketSheet({required this.onCreated});

  @override
  ConsumerState<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<_CreateTicketSheet> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      AppSnackBar.info(context, 'Nhập tiêu đề và nội dung');
      return;
    }
    setState(() => _submitting = true);
    final (ok, msg, id) =
        await ref.read(supportTicketActionsProvider.notifier).createTicket(
              subject: _subjectCtrl.text.trim(),
              message: _messageCtrl.text.trim(),
              contact: _contactCtrl.text.trim().isEmpty
                  ? null
                  : _contactCtrl.text.trim(),
              category: 'support',
            );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      AppSnackBar.error(context, msg);
      return;
    }
    if (id != null && id.isNotEmpty) {
      widget.onCreated(id);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tạo yêu cầu hỗ trợ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contactCtrl,
            decoration: const InputDecoration(
              labelText: 'Liên hệ (tuỳ chọn)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }
}
