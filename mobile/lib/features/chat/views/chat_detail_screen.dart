import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/message_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_thread_controller.dart';
import '../utils/chat_time.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';

/// Màn chat chi tiết 1 conversation: lịch sử tin + soạn tin realtime.
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // reverse:true → maxScrollExtent là phía tin cũ nhất (trên cùng).
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(chatThreadProvider(widget.conversationId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final id = widget.conversationId;
    final state = ref.watch(chatThreadProvider(id));
    final notifier = ref.read(chatThreadProvider(id).notifier);
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final detailAsync = ref.watch(conversationDetailProvider(id));

    final title = detailAsync.maybeWhen(
      data: (c) => c.displayTitle(currentUserId),
      orElse: () => 'Tin nhắn',
    );

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (state.someoneTyping)
              Text(
                'đang nhập...',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: colors.brand,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(state, notifier, currentUserId, colors),
          ),
          ChatComposer(
            onSend: notifier.send,
            onTyping: notifier.notifyTyping,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    ChatThreadState state,
    ChatThreadNotifier notifier,
    String currentUserId,
    AppColorScheme colors,
  ) {
    if (state.isLoadingInitial) {
      return const LoadingWidget();
    }
    if (state.error != null && state.messages.isEmpty) {
      return ErrorStateWidget(
        message: state.error!,
        onRetry: notifier.loadInitial,
      );
    }
    if (state.messages.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.chat_bubble_outline_rounded,
        message: 'Bắt đầu cuộc trò chuyện',
        subMessage: 'Gửi tin nhắn đầu tiên cho khách.',
      );
    }

    // Build item list oldest-first (chèn separator ngày), rồi đảo cho reverse.
    final items = _buildItems(state.messages);
    final reversed = items.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: reversed.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= reversed.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final item = reversed[index];
        if (item is _DaySeparator) {
          return _DaySeparatorWidget(label: item.label);
        }
        final message = (item as _MessageItem).message;
        final isMine = message.senderId == currentUserId;
        return MessageBubble(
          message: message,
          isMine: isMine,
          onRetry: () => notifier.retry(message),
          onLongPress:
              isMine ? () => _showMessageActions(message, notifier) : null,
        );
      },
    );
  }

  List<Object> _buildItems(List<MessageModel> messages) {
    final items = <Object>[];
    DateTime? lastDay;
    for (final m in messages) {
      if (lastDay == null || ChatTime.isDifferentDay(lastDay, m.createdAt)) {
        items.add(_DaySeparator(ChatTime.daySeparator(m.createdAt)));
        lastDay = m.createdAt;
      }
      items.add(_MessageItem(m));
    }
    return items;
  }

  Future<void> _showMessageActions(
    MessageModel message,
    ChatThreadNotifier notifier,
  ) async {
    final canEdit = notifier.canEdit(message);
    final canDelete = notifier.canDelete(message);
    if (!canEdit && !canDelete) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Sửa tin nhắn'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditDialog(message, notifier);
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded,
                      color: context.colors.error),
                  title: Text('Xoá tin nhắn',
                      style: TextStyle(color: context.colors.error)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final err = await notifier.deleteMessage(message);
                    if (err != null && mounted) {
                      AppSnackBar.error(context, err);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    MessageModel message,
    ChatThreadNotifier notifier,
  ) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sửa tin nhắn'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 1,
            decoration: const InputDecoration(hintText: 'Nội dung tin nhắn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    final err = await notifier.editMessage(message, result);
    if (err != null && mounted) {
      AppSnackBar.error(context, err);
    }
  }
}

// ── Item types cho list ──────────────────────────────────────────────────────

class _DaySeparator {
  final String label;
  const _DaySeparator(this.label);
}

class _MessageItem {
  final MessageModel message;
  const _MessageItem(this.message);
}

class _DaySeparatorWidget extends StatelessWidget {
  final String label;
  const _DaySeparatorWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors.bgSurfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
