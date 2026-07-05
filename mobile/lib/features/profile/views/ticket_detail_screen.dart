import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/account_controller.dart';
import '../data/models/account_models.dart';
import '../widgets/attachment_picker.dart';

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
  List<String> _attachments = const [];
  bool _uploadingAttachment = false;
  // Đổi key để reset AttachmentPicker (xoá thumbnail) sau khi gửi xong.
  int _pickerEpoch = 0;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _reply(SupportTicket ticket) async {
    final msg = _replyCtrl.text.trim();
    if (msg.isEmpty && _attachments.isEmpty) return;
    if (_uploadingAttachment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải ảnh lên, vui lòng đợi')),
      );
      return;
    }
    setState(() => _sending = true);
    final result = await ref.read(accountRepositoryProvider).replyTicket(
          ticket.id,
          msg,
          attachments: _attachments,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.success) {
      _replyCtrl.clear();
      setState(() {
        _attachments = const [];
        _pickerEpoch++;
      });
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
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ticketDetailProvider(widget.ticketId));
                  await ref.read(ticketDetailProvider(widget.ticketId).future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
            ),
            if (!ticket.isClosed)
              _ReplyBar(
                controller: _replyCtrl,
                sending: _sending,
                onSend: () => _reply(ticket),
                picker: AttachmentPicker(
                  key: ValueKey(_pickerEpoch),
                  onChanged: (urls) => _attachments = urls,
                  onBusyChanged: (busy) =>
                      setState(() => _uploadingAttachment = busy),
                ),
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
          if (ticket.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            _AttachmentThumbs(urls: ticket.attachments),
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
            if (message.message.isNotEmpty)
              Text(
                message.message,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: fromAdmin ? colors.textPrimary : colors.textOnPrimary,
                ),
              ),
            if (message.attachments.isNotEmpty) ...[
              if (message.message.isNotEmpty) const SizedBox(height: 6),
              _AttachmentThumbs(urls: message.attachments),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lưới thumbnail attachment (ảnh/pdf) trong ticket. Ảnh → mở fullscreen
/// (PhotoView); pdf/khác → mở bằng trình duyệt ngoài.
class _AttachmentThumbs extends StatelessWidget {
  final List<String> urls;
  const _AttachmentThumbs({required this.urls});

  static bool _isImage(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  Future<void> _open(BuildContext context, String url) async {
    if (_isImage(url)) {
      await showDialog<void>(
        context: context,
        builder: (_) => _ImageViewerDialog(url: url),
      );
    } else {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls.map((url) {
        final isImage = _isImage(url);
        return GestureDetector(
          onTap: () => _open(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 64,
              height: 64,
              child: isImage
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      memCacheWidth: 250,
                      placeholder: (_, __) =>
                          Container(color: colors.bgSurfaceContainer),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.bgSurfaceContainer,
                        child: Icon(Icons.broken_image_outlined,
                            color: colors.textTertiary, size: 22),
                      ),
                    )
                  : Container(
                      color: colors.bgSurfaceContainer,
                      child: Icon(Icons.picture_as_pdf_outlined,
                          color: colors.error, size: 26),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImageViewerDialog extends StatelessWidget {
  final String url;
  const _ImageViewerDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(url),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final Widget picker;

  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.picker,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          picker,
          const SizedBox(height: AppSpacing.sm),
          Row(
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
        ],
      ),
    );
  }
}
