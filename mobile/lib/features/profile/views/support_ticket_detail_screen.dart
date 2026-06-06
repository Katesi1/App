import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/profile_settings_controller.dart';
import '../data/models/support_ticket.dart';

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final (ok, msg) = await ref
        .read(supportTicketActionsProvider.notifier)
        .reply(widget.ticketId, text);
    if (!mounted) return;
    setState(() => _sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? null : context.colors.error,
      ),
    );
    if (ok) _replyCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(supportTicketDetailProvider(widget.ticketId));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
      body: detailAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(supportTicketDetailProvider(widget.ticketId)),
        ),
        data: (detail) {
          final ticket = detail.ticket;
          final isClosed = ticket.status.toLowerCase() == 'resolved' ||
              ticket.status.toLowerCase() == 'closed';

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    supportTicketDetailProvider(widget.ticketId),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Container(
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
                              ticket.subject,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${ticket.displayCode} · ${ticket.statusLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...detail.messages.map(
                        (m) => _MessageBubble(message: m),
                      ),
                      if (detail.messages.isEmpty)
                        EmptyStateWidget(
                          icon: Icons.chat_bubble_outline,
                          message: 'Chưa có tin nhắn trong ticket này',
                        ),
                    ],
                  ),
                ),
              ),
              if (!isClosed)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyCtrl,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Nhập phản hồi...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _sendReply,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportTicketMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isStaff = message.isStaff;
    final time = message.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(message.createdAt!.toLocal())
        : '';

    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isStaff
              ? colors.bgSurfaceContainer
              : colors.brand.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isStaff ? colors.borderDefault : colors.brand,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStaff ? 'Hỗ trợ' : 'Bạn',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(message.body, style: TextStyle(color: colors.textPrimary)),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(fontSize: 10, color: colors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
