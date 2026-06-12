import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

/// Ô soạn tin nhắn ở đáy màn chat. Tự throttle typing event (1 emit / 3s) +
/// emit stop sau 3s không gõ.
class ChatComposer extends StatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<bool>? onTyping;
  final bool enabled;

  const ChatComposer({
    super.key,
    required this.onSend,
    this.onTyping,
    this.enabled = true,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _canSend = false;
  DateTime? _lastTypingEmit;
  Timer? _typingStopTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _canSend) {
      setState(() => _canSend = hasText);
    }
    if (hasText) _emitTyping();
  }

  void _emitTyping() {
    final now = DateTime.now();
    final last = _lastTypingEmit;
    if (last == null || now.difference(last).inSeconds >= 3) {
      _lastTypingEmit = now;
      widget.onTyping?.call(true);
    }
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 3), () {
      _lastTypingEmit = null;
      widget.onTyping?.call(false);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _typingStopTimer?.cancel();
    _lastTypingEmit = null;
    widget.onTyping?.call(false);
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhắn tin...',
                  hintStyle: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: colors.textTertiary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SendButton(enabled: _canSend && widget.enabled, onTap: _send),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedScale(
      scale: enabled ? 1 : 0.85,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: enabled ? colors.brand : colors.bgSurfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.send_rounded,
              size: 20,
              color: enabled ? colors.textOnPrimary : colors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
