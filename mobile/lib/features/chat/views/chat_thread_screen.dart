import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../data/models/message_model.dart';
import '../widgets/message_bubble.dart';

/// Màn hội thoại realtime — lịch sử (REST) + tin tới tức thì (Socket.IO).
class ChatThreadScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatThreadScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  /// reverse:true → cuộn lên tin cũ tiến tới maxScrollExtent → tải thêm.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(chatThreadProvider(widget.conversationId).notifier).loadMore();
    }
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(chatThreadProvider(widget.conversationId).notifier).send(text);
    _inputCtrl.clear();
    // reverse:true → đáy danh sách ở offset 0.
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final myUserId = ref.watch(currentUserProvider)?.id ?? '';
    final state = ref.watch(chatThreadProvider(widget.conversationId));
    final detail = ref.watch(conversationDetailProvider(widget.conversationId));
    final title = detail.valueOrNull?.titleFor(myUserId) ?? 'Tin nhắn';

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(child: _buildMessages(state, myUserId, colors)),
          _InputBar(controller: _inputCtrl, onSend: _send),
        ],
      ),
    );
  }

  Widget _buildMessages(
    ChatThreadState state,
    String myUserId,
    AppColorScheme colors,
  ) {
    if (state.loading) return const LoadingWidget();
    if (state.error != null && state.messages.isEmpty) {
      return ErrorStateWidget(
        message: state.error!,
        onRetry: () =>
            ref.invalidate(chatThreadProvider(widget.conversationId)),
      );
    }
    if (state.messages.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.chat_bubble_outline_rounded,
        message: 'Hãy gửi tin nhắn đầu tiên',
      );
    }

    final count = state.messages.length;
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: count + (state.loadingMore ? 1 : 0),
      itemBuilder: (_, index) {
        // Phần tử cuối (cao nhất) = spinner tải thêm tin cũ.
        if (index >= count) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final message = state.messages[count - 1 - index];
        final isMine = message.senderId == myUserId;
        final notifier =
            ref.read(chatThreadProvider(widget.conversationId).notifier);
        final canModify = notifier.canModify(message);
        return GestureDetector(
          onLongPress: canModify ? () => _showMessageActions(message) : null,
          child: MessageBubble(message: message, isMine: isMine),
        );
      },
    );
  }

  /// Bottom sheet hành động cho tin của chính mình (còn trong 15 phút).
  void _showMessageActions(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _editMessage(message);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: context.colors.error),
              title: Text('Xoá', style: TextStyle(color: context.colors.error)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(ChatMessage message) async {
    final ctrl = TextEditingController(text: message.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Chỉnh sửa tin nhắn'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (newContent == null ||
        newContent.isEmpty ||
        newContent == message.content) {
      return;
    }
    final error = await ref
        .read(chatThreadProvider(widget.conversationId).notifier)
        .edit(message.id, newContent);
    if (!mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error);
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xoá tin nhắn'),
        content: const Text('Bạn có chắc muốn xoá tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: context.colors.error),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await ref
        .read(chatThreadProvider(widget.conversationId).notifier)
        .delete(message.id);
    if (!mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error);
    }
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

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
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
