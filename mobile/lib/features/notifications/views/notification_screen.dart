import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/notification_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/notification_controller.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  NotificationType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationActionsProvider.notifier).markAllAsRead();
            },
            child: Text(
              'Đọc tất cả',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.brand,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ───────────────────────────────────
          _FilterBar(
            selected: _selectedType,
            onChanged: (type) => setState(() => _selectedType = type),
          ),

          // ── List ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationListProvider);
                await ref.read(notificationListProvider.future);
              },
              child: notificationsAsync.when(
                data: (notifications) {
                  final filtered = _selectedType == null
                      ? notifications
                      : notifications
                          .where((n) => n.type == _selectedType)
                          .toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        EmptyStateWidget(
                          icon: Icons.notifications_off_outlined,
                          message: 'Không có thông báo',
                          subMessage:
                              'Bạn sẽ nhận thông báo khi có cập nhật mới',
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      return _NotificationCard(
                        notification: notification,
                        onTap: () {
                          // Navigate to detail. Detail screen auto-marks as read
                          // after mount + shows smart "Open link" button per
                          // targetType (booking/kyc/payment).
                          context.push('/notifications/${notification.id}');
                        },
                      );
                    },
                  );
                },
                loading: () => SkeletonList(
                  skeleton: const UserCardSkeleton(),
                  count: 6,
                ),
                error: (e, _) => ErrorStateWidget(
                  message: e.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.invalidate(notificationListProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final NotificationType? selected;
  final ValueChanged<NotificationType?> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _chip(
            context: context,
            label: 'Tất cả',
            isActive: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          ...NotificationType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: _chip(
                context: context,
                label: type.label,
                isActive: selected == type,
                onTap: () => onChanged(type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? colors.brand : colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive ? colors.brand : colors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? colors.textOnPrimary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─── Notification Card ───────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                _buildIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.subtitle,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Unread dot — only shown when unread. After mark-as-read,
                // dot disappears entirely (doesn't fade to grey).
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.brand,
                    ),
                  ),
                Text(
                  _timeAgo(notification.createdAt),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colors = context.colors;
    final (IconData icon, Color color) = switch (notification.type) {
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

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
