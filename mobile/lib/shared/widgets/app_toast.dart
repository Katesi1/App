import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

enum ToastType { success, error, info, warning }

/// Toast kiểu "toastify" — overlay nổi từ trên xuống, có màu + icon theo loại,
/// tự ẩn sau vài giây, vuốt/chạm để đóng. Dùng app-wide:
///
/// ```dart
/// AppToast.error(context, 'Thanh toán thất bại');
/// AppToast.success(context, 'Đã lưu');
/// ```
class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void success(BuildContext context, String message) =>
      show(context, message, ToastType.success);
  static void error(BuildContext context, String message) =>
      show(context, message, ToastType.error);
  static void info(BuildContext context, String message) =>
      show(context, message, ToastType.info);
  static void warning(BuildContext context, String message) =>
      show(context, message, ToastType.warning);

  static void show(
    BuildContext context,
    String message,
    ToastType type, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Single-slot: thay toast hiện tại nếu có.
    _dismiss();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastCard(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _ToastCard extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastCard({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({Color accent, IconData icon}) _style(AppColorScheme colors) =>
      switch (widget.type) {
        ToastType.success => (
            accent: colors.success,
            icon: Icons.check_circle_rounded
          ),
        ToastType.error => (accent: colors.error, icon: Icons.error_rounded),
        ToastType.warning => (
            accent: colors.warning,
            icon: Icons.warning_rounded
          ),
        ToastType.info => (accent: colors.brand, icon: Icons.info_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = _style(colors);
    final media = MediaQuery.of(context);

    return Positioned(
      top: media.padding.top + 10,
      left: 12,
      right: 12,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value * 80),
            child: child,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Dismissible(
                key: const ValueKey('app_toast'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.bgSurfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderDefault),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: s.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.icon, color: s.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
