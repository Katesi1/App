import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/account_controller.dart';
import '../data/models/account_models.dart';

/// Yêu cầu hỗ trợ của tôi (`GET/POST /support/tickets`).
class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  Color _statusColor(SupportTicket t, AppColorScheme colors) =>
      switch (t.status) {
        'resolved' || 'closed' => colors.success,
        'in_progress' => colors.brand,
        _ => colors.warning,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final ticketsAsync = ref.watch(ticketListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu hỗ trợ của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tạo yêu cầu'),
      ),
      body: ticketsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(ticketListProvider),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.support_agent_outlined,
              message: 'Bạn chưa có yêu cầu hỗ trợ nào',
            );
          }
          return RefreshIndicator(
            color: colors.brand,
            onRefresh: () async => ref.invalidate(ticketListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = tickets[i];
                return _TicketTile(
                  ticket: t,
                  statusColor: _statusColor(t, colors),
                  onTap: () => context.push('/profile/tickets/${t.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateTicketSheet(),
    );
    if (created == true) ref.invalidate(ticketListProvider);
  }
}

class _TicketTile extends StatelessWidget {
  final SupportTicket ticket;
  final Color statusColor;
  final VoidCallback onTap;

  const _TicketTile({
    required this.ticket,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
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
                    '${ticket.code} · ${ticket.subject}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    ticket.statusLabel,
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
            Row(
              children: [
                Icon(Icons.label_outline, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  ticket.categoryLabel,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet tạo ticket mới.
class _CreateTicketSheet extends ConsumerStatefulWidget {
  const _CreateTicketSheet();

  @override
  ConsumerState<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends ConsumerState<_CreateTicketSheet> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'account';
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (subject.length < 5 || desc.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề ≥ 5 ký tự và mô tả ≥ 10 ký tự')),
      );
      return;
    }
    setState(() => _sending = true);
    final result = await ref.read(accountRepositoryProvider).createTicket(
          subject: subject,
          category: _category,
          description: desc,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu hỗ trợ')),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tạo yêu cầu hỗ trợ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: kTicketCategories
                .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? 'account'),
            decoration: const InputDecoration(labelText: 'Danh mục'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              hintText: 'Tóm tắt ngắn gọn vấn đề',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Mô tả chi tiết',
              hintText: 'Mô tả vấn đề bạn gặp phải...',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _sending ? null : _submit,
              child: Text(_sending ? 'Đang gửi...' : 'Gửi yêu cầu'),
            ),
          ),
        ],
      ),
    );
  }
}
