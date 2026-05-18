import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/notification_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/notification_controller.dart';

/// Notification detail screen. Resolves model by `id` from
/// `notificationListProvider` (backend has no separate detail endpoint).
///
/// On mount: auto-calls `markAsRead` if unread → list updates when user
/// navigates back (provider invalidate).
///
/// Smart navigation: if `targetType` + `targetId` present → "Open link" button
/// → pushes to related resource (booking, kyc, payment...).
class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const NotificationDetailScreen({super.key, required this.id});

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  bool _markedAsRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeMarkRead());
  }

  Future<void> _maybeMarkRead() async {
    if (_markedAsRead) return;
    final list = ref.read(notificationListProvider).valueOrNull;
    if (list == null) return;
    final notification = _findById(list, widget.id);
    if (notification == null || notification.isRead) return;
    _markedAsRead = true;
    await ref
        .read(notificationActionsProvider.notifier)
        .markAsRead(widget.id);
  }

  NotificationModel? _findById(List<NotificationModel> list, String id) {
    for (final n in list) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final listAsync = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
      ),
      body: listAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(notificationListProvider),
        ),
        data: (list) {
          final notification = _findById(list, widget.id);
          if (notification == null) {
            return const EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              message: 'Không tìm thấy thông báo',
              subMessage: 'Thông báo có thể đã bị xoá',
            );
          }
          // Mark-as-read after list loads successfully (postFrame in init
          // runs before list async load completes).
          if (!_markedAsRead && !notification.isRead) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _maybeMarkRead());
          }
          return _DetailBody(notification: notification);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final NotificationModel notification;
  const _DetailBody({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (IconData icon, Color color) = _iconForType(colors);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Header card: icon + type badge.
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.type.label.toUpperCase(),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(notification.createdAt),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          notification.title,
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            height: 1.35,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          notification.subtitle.isEmpty
              ? '(Không có nội dung chi tiết)'
              : notification.subtitle,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
            height: 1.55,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Smart action button (if target present).
        if (_resolveTargetRoute(notification) != null)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _openTarget(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(_targetButtonLabel(notification)),
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: AppColors.darkBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                textStyle: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  (IconData, Color) _iconForType(AppColorScheme colors) =>
      switch (notification.type) {
        NotificationType.booking => (
            Icons.calendar_today_rounded,
            colors.brand,
          ),
        NotificationType.payment => (
            Icons.receipt_long_rounded,
            colors.success,
          ),
        NotificationType.system => (
            Icons.sync_rounded,
            colors.brandSecondary,
          ),
      };

  void _openTarget(BuildContext context) {
    final route = _resolveTargetRoute(notification);
    if (route != null) context.push(route);
  }

  /// Maps (`type`, `targetType`, `targetId`) → route. Returns `null` if
  /// notification has no linked resource (e.g. generic `system` notification).
  static String? _resolveTargetRoute(NotificationModel n) {
    final id = n.targetId;
    final t = n.targetType?.toLowerCase();

    // KYC events
    if (t == 'kyc' || t == 'kyc_submission') {
      // Multiple states — route to dashboard, banner will navigate to the
      // correct paywall/pending/approved/rejected screen.
      return '/dashboard';
    }

    // Booking events
    if (t == 'booking' && id != null) {
      return '/bookings';
    }
    if (n.type == NotificationType.booking) {
      return '/bookings';
    }

    // Payment events
    if (t == 'payment' || n.type == NotificationType.payment) {
      return '/profile/help';
    }

    // System / general — no specific route.
    return null;
  }

  String _targetButtonLabel(NotificationModel n) {
    final t = n.targetType?.toLowerCase();
    if (t == 'kyc' || t == 'kyc_submission') return 'Xem trạng thái xác minh';
    if (t == 'booking' || n.type == NotificationType.booking) {
      return 'Xem booking';
    }
    if (t == 'payment' || n.type == NotificationType.payment) {
      return 'Xem chi tiết thanh toán';
    }
    return 'Mở liên kết';
  }

  String _formatDate(DateTime dt) {
    return DateFormat('HH:mm · dd/MM/yyyy', 'vi').format(dt);
  }
}
