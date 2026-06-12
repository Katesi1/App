import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/message_model.dart';
import '../utils/chat_time.dart';

/// 1 bong bóng tin nhắn. [isMine] = tin của user hiện tại (canh phải, màu brand).
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isSystem) {
      return _SystemLine(content: message.content);
    }

    final bubbleColor = isMine
        ? colors.brand
        : (isDark ? colors.bgSurfaceElevated : colors.bgSurfaceContainer);
    final textColor = isMine ? colors.textOnPrimary : colors.textPrimary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: message.isDeleted ? null : onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 2,
            horizontal: AppSpacing.md,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 1,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(isMine ? AppRadius.lg : AppRadius.xs),
              bottomRight:
                  Radius.circular(isMine ? AppRadius.xs : AppRadius.lg),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.hasAttachments && !message.isDeleted)
                _Attachments(message: message),
              if (message.content.isNotEmpty || message.isDeleted)
                Text(
                  message.isDeleted ? 'Tin nhắn đã bị xoá' : message.content,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    height: 1.35,
                    fontStyle:
                        message.isDeleted ? FontStyle.italic : FontStyle.normal,
                    color: message.isDeleted
                        ? textColor.withValues(alpha: 0.6)
                        : textColor,
                  ),
                ),
              const SizedBox(height: 3),
              _MetaRow(
                message: message,
                isMine: isMine,
                textColor: textColor,
                onRetry: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final Color textColor;
  final VoidCallback? onRetry;

  const _MetaRow({
    required this.message,
    required this.isMine,
    required this.textColor,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final faint = textColor.withValues(alpha: 0.7);
    final children = <Widget>[
      if (message.isEdited && !message.isDeleted)
        Text(
          'đã sửa · ',
          style: GoogleFonts.beVietnamPro(fontSize: 10, color: faint),
        ),
      Text(
        ChatTime.messageTime(message.createdAt),
        style: GoogleFonts.beVietnamPro(fontSize: 10, color: faint),
      ),
    ];

    if (isMine && !message.isDeleted) {
      children.add(const SizedBox(width: 4));
      children.add(_statusIcon(context, faint));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _statusIcon(BuildContext context, Color faint) {
    switch (message.sendStatus) {
      case MessageSendStatus.sending:
        return SizedBox(
          width: 11,
          height: 11,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: faint),
        );
      case MessageSendStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: Icon(Icons.error_outline_rounded,
              size: 13, color: context.colors.error),
        );
      case MessageSendStatus.sent:
        return Icon(Icons.done_rounded, size: 13, color: faint);
    }
  }
}

class _Attachments extends StatelessWidget {
  final MessageModel message;
  const _Attachments({required this.message});

  @override
  Widget build(BuildContext context) {
    final images = message.attachments.where((a) => a.isImage).toList();
    if (images.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final img in images)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: CachedNetworkImage(
                  imageUrl: img.url,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  width: 220,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  final String content;
  const _SystemLine({required this.content});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: colors.bgSurfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            content,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: colors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
