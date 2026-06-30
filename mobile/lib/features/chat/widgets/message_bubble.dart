import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/models/message_model.dart';

/// Bong bóng 1 tin nhắn chat. [isMine] → căn phải + màu brand.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const MessageBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (message.isDeleted) {
      return _wrap(
        context,
        child: Text(
          'Tin nhắn đã bị xoá',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: isMine ? colors.textOnPrimary : colors.textTertiary,
          ),
        ),
      );
    }

    return _wrap(
      context,
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.attachments.isNotEmpty)
            Padding(
              padding:
                  EdgeInsets.only(bottom: message.content.isNotEmpty ? 6 : 0),
              child: _Attachments(attachments: message.attachments),
            ),
          if (message.content.isNotEmpty)
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isMine ? colors.textOnPrimary : colors.textPrimary,
              ),
            ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isEdited)
                Text(
                  'đã chỉnh sửa · ',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: (isMine ? colors.textOnPrimary : colors.textTertiary)
                        .withValues(alpha: 0.7),
                  ),
                ),
              Text(
                message.createdAt != null
                    ? DateFormat('HH:mm').format(message.createdAt!.toLocal())
                    : '',
                style: TextStyle(
                  fontSize: 10,
                  color: (isMine ? colors.textOnPrimary : colors.textTertiary)
                      .withValues(alpha: 0.8),
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 4),
                _statusIcon(colors),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(AppColorScheme colors) {
    return switch (message.sendStatus) {
      MessageSendStatus.sending => SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.4,
            color: colors.textOnPrimary.withValues(alpha: 0.8),
          ),
        ),
      MessageSendStatus.failed =>
        Icon(Icons.error_outline_rounded, size: 12, color: colors.error),
      MessageSendStatus.sent => Icon(Icons.check_rounded,
          size: 12, color: colors.textOnPrimary.withValues(alpha: 0.8)),
    };
  }

  Widget _wrap(BuildContext context, {required Widget child}) {
    final colors = context.colors;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isMine ? colors.brand : colors.bgSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
          border: isMine ? null : Border.all(color: colors.borderDefault),
        ),
        child: child,
      ),
    );
  }
}

class _Attachments extends StatelessWidget {
  final List<ChatAttachment> attachments;
  const _Attachments({required this.attachments});

  Future<void> _open(BuildContext context, ChatAttachment a) async {
    if (a.isImage) {
      await showDialog<void>(
        context: context,
        builder: (_) => _ImageViewer(url: a.url),
      );
    } else {
      await launchUrl(Uri.parse(a.url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: attachments.map((a) {
        return GestureDetector(
          onTap: () => _open(context, a),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 120,
              height: 120,
              child: a.isImage
                  ? CachedNetworkImage(
                      imageUrl: a.url,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      placeholder: (_, __) =>
                          Container(color: colors.bgSurfaceContainer),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.bgSurfaceContainer,
                        child: Icon(Icons.broken_image_outlined,
                            color: colors.textTertiary),
                      ),
                    )
                  : Container(
                      color: colors.bgSurfaceContainer,
                      child: Icon(Icons.insert_drive_file_outlined,
                          color: colors.textSecondary, size: 30),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String url;
  const _ImageViewer({required this.url});

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
