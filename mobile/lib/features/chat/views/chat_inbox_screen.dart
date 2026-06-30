import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../services/chat_socket_service.dart';
import '../widgets/conversation_tile.dart';

/// Inbox chat — danh sách hội thoại của user (OWNER/SALE trả lời khách booking).
class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final myUserId = ref.watch(currentUserProvider)?.id ?? '';
    final listAsync = ref.watch(conversationListProvider);

    // Có tin mới qua socket → refresh inbox + badge.
    ref.listen(chatSocketEventsProvider, (_, next) {
      final event = next.valueOrNull;
      if (event is MessageNewEvent ||
          event is ReadUpdateEvent ||
          event is SocketConnected) {
        ref.invalidate(conversationListProvider);
      }
    });

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: listAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(conversationListProvider),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              message: 'Chưa có cuộc trò chuyện nào',
            );
          }
          return RefreshIndicator(
            color: colors.brand,
            onRefresh: () async {
              ref.invalidate(conversationListProvider);
              await ref.read(conversationListProvider.future);
            },
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 76,
                color: colors.borderDefault,
              ),
              itemBuilder: (_, i) {
                final c = conversations[i];
                return ConversationTile(
                  conversation: c,
                  myUserId: myUserId,
                  onTap: () => context.push('/conversations/${c.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
