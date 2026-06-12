import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/conversation_model.dart';
import '../utils/chat_time.dart';

/// 1 dòng hội thoại trong inbox.
class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = conversation.displayTitle(currentUserId);
    final other = conversation.counterpart(currentUserId);
    final preview = conversation.lastMessagePreview?.trim();
    final hasUnread = conversation.hasUnread;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(name: title, avatarUrl: other?.user?.avatar),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        ChatTime.inboxLabel(conversation.lastMessageAt),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: hasUnread ? colors.brand : colors.textTertiary,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _TypeChip(type: conversation.type),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          preview == null || preview.isEmpty
                              ? 'Chưa có tin nhắn'
                              : preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: hasUnread
                                ? colors.textPrimary
                                : colors.textTertiary,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _UnreadBadge(count: conversation.myUnread),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _Avatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.brandLight.withValues(alpha: 0.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 120,
              errorWidget: (_, __, ___) => _initialAvatar(colors, initial),
              placeholder: (_, __) => _initialAvatar(colors, initial),
            )
          : _initialAvatar(colors, initial),
    );
  }

  Widget _initialAvatar(AppColorScheme colors, String initial) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.brand,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ConversationType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        type.label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}
