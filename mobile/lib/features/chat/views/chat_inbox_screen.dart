import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../widgets/conversation_tile.dart';

/// Inbox — danh sách hội thoại của user hiện tại (chủ homestay / SALE / admin
/// trả lời khách đặt phòng từ web + hỗ trợ + nội bộ).
class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.forum_outlined,
              message: 'Chưa có tin nhắn',
              subMessage:
                  'Khi khách đặt phòng nhắn tin, cuộc trò chuyện sẽ hiện ở đây.',
            );
          }
          return RefreshIndicator(
            color: colors.brand,
            onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 76,
                color: colors.borderSubtle,
              ),
              itemBuilder: (_, i) {
                final conv = conversations[i];
                return ConversationTile(
                  conversation: conv,
                  currentUserId: currentUserId,
                  onTap: () {
                    ref
                        .read(conversationsProvider.notifier)
                        .markReadLocally(conv.id);
                    context.push('/chat/${conv.id}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
