import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/chat_controller.dart';

/// Mở chat từ 1 booking: tạo (hoặc lấy) hội thoại `type=booking` rồi thay thế
/// chính nó bằng màn thread. Tách route giúp màn booking KHÔNG phải import chéo
/// repository chat — chỉ cần push `/conversations/by-booking/:bookingId`.
class ChatBookingResolverScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const ChatBookingResolverScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ChatBookingResolverScreen> createState() =>
      _ChatBookingResolverScreenState();
}

class _ChatBookingResolverScreenState
    extends ConsumerState<ChatBookingResolverScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final result = await ref
        .read(chatRepositoryProvider)
        .createOrGetBookingConversation(widget.bookingId);
    if (!mounted) return;
    if (result.success) {
      // Replace để back từ thread quay về booking, không kẹt ở màn resolver.
      context.pushReplacement('/conversations/${result.data!.id}');
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: _error == null
          ? const LoadingWidget()
          : ErrorStateWidget(
              message: _error!,
              onRetry: () {
                setState(() => _error = null);
                _resolve();
              },
            ),
    );
  }
}
