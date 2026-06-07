import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/account_controller.dart';
import '../data/models/account_models.dart';

/// Chi tiết ticket hỗ trợ + lịch sử trao đổi + trả lời
/// (`GET /support/tickets/:id`, `POST /support/tickets/:id/reply`).
class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _reply(SupportTicket ticket) async {
    final msg = _replyCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    final result =
        await ref.read(accountRepositoryProvider).replyTicket(ticket.id, msg);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.success) {
      _replyCtrl.clear();
      FocusScope.of(context).unfocus();
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(ticketListProvider);
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
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
      body: ticketAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(ticketDetailProvider(widget.ticketId)),
        ),
        data: (ticket) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _HeaderCard(ticket: ticket),
                  const SizedBox(height: AppSpacing.md),
                  if (ticket.messages.isEmpty)
                    Text(
                      'Chưa có trao đổi nào.',
                      style: TextStyle(color: colors.textTertiary),
                    )
                  else
                    ...ticket.messages.map((m) => _MessageBubble(message: m)),
                ],
              ),
            ),
            if (!ticket.isClosed)
              _ReplyBar(
                controller: _replyCtrl,
                sending: _sending,
                onSend: () => _reply(ticket),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: colors.bgSurfaceContainer,
                child: Text(
                  'Yêu cầu đã đóng. Tạo yêu cầu mới nếu bạn cần hỗ trợ thêm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final SupportTicket ticket;
  const _HeaderCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = switch (ticket.status) {
      'resolved' || 'closed' => colors.success,
      'in_progress' => colors.brand,
      _ => colors.warning,
    };
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
              Text(
                ticket.code,
                style: TextStyle(
                  color: colors.textBrand,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
          const SizedBox(height: 8),
          Text(
            ticket.subject,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.categoryLabel,
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
          if (ticket.description != null && ticket.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ticket.description!,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: 13, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fromAdmin = message.fromAdmin;
    return Align(
      alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: fromAdmin ? colors.bgSurface : colors.brand,
          borderRadius: BorderRadius.circular(14),
          border: fromAdmin ? Border.all(color: colors.borderDefault) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fromAdmin)
              Text(
                'Hỗ trợ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.textBrand,
                ),
              ),
            Text(
              message.message,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: fromAdmin ? colors.textPrimary : colors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Nhập trả lời...',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
