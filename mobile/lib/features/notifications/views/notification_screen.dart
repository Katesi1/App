import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/notification_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/section_label.dart';
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
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: notificationsAsync.when(
        data: (notifications) {
          final filtered = _selectedType == null
              ? notifications
              : notifications.where((n) => n.type == _selectedType).toList();
          final unread = notifications.where((n) => !n.isRead).length;

          return Column(
            children: [
              // ── Summary + đọc tất cả ─────────────────────────────
              _SummaryBar(
                unread: unread,
                onMarkAll: unread == 0
                    ? null
                    : () => ref
                        .read(notificationActionsProvider.notifier)
                        .markAllAsRead(),
              ),

              // ── Filter chips ─────────────────────────────────────
              _FilterBar(
                selected: _selectedType,
                onChanged: (type) => setState(() => _selectedType = type),
              ),

              // ── List ─────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationListProvider);
                    await ref.read(notificationListProvider.future);
                  },
                  child: _buildList(filtered),
                ),
              ),
            ],
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
    );
  }

  Widget _buildList(List<NotificationModel> filtered) {
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          EmptyStateWidget(
            icon: Icons.notifications_off_outlined,
            message: 'Không có thông báo',
            subMessage: 'Bạn sẽ nhận thông báo khi có cập nhật mới',
          ),
        ],
      );
    }

    // Chèn header nhóm ngày (Hôm nay / Hôm qua / 7 ngày qua / Cũ hơn) giữa các
    // card — danh sách BE trả sẵn theo createdAt desc.
    final entries = <_ListEntry>[];
    String? lastGroup;
    for (final n in filtered) {
      final group = _dateGroup(n.createdAt);
      if (group != lastGroup) {
        entries.add(_HeaderEntry(group));
        lastGroup = group;
      }
      entries.add(_CardEntry(n));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xxl),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is _HeaderEntry) {
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? AppSpacing.xs : AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: SectionLabel(label: entry.label),
          );
        }
        final notification = (entry as _CardEntry).notification;
        return _NotificationCard(
          notification: notification,
          // Detail screen tự mark-as-read sau khi mount + nút mở link theo
          // targetType (booking/kyc/payment).
          onTap: () => context.push('/notifications/${notification.id}'),
        );
      },
    );
  }

  static String _dateGroup(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    if (diff < 7) return '7 ngày qua';
    return 'Cũ hơn';
  }
}

// Entry của list gộp: header ngày hoặc 1 card thông báo.
sealed class _ListEntry {
  const _ListEntry();
}

class _HeaderEntry extends _ListEntry {
  final String label;
  const _HeaderEntry(this.label);
}

class _CardEntry extends _ListEntry {
  final NotificationModel notification;
  const _CardEntry(this.notification);
}

// ─── Summary Bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int unread;
  final VoidCallback? onMarkAll;

  const _SummaryBar({required this.unread, this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              unread == 0 ? 'Bạn đã đọc hết thông báo' : '$unread chưa đọc',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: unread == 0 ? colors.textTertiary : colors.textPrimary,
              ),
            ),
          ),
          if (onMarkAll != null)
            TextButton.icon(
              onPressed: onMarkAll,
              icon: Icon(Icons.done_all_rounded, size: 16, color: colors.brand),
              label: Text(
                'Đọc tất cả',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.brand,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = !notification.isRead;
    final (_, accent) = _iconStyle(colors);

    // Unread nổi bật bằng nền brand-tint nhạt + viền brand; read thì phẳng.
    final bg = unread
        ? colors.brand.withValues(alpha: isDark ? 0.14 : 0.05)
        : colors.bgSurface;
    final border = unread ? colors.borderBrand : colors.borderDefault;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5),
                              decoration:
                                  BoxDecoration(shape: BoxShape.circle, color: accent),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.subtitle,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          height: 1.35,
                          color: colors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: colors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgo(notification.createdAt),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color) _iconStyle(AppColorScheme colors) {
    return switch (notification.type) {
      NotificationType.booking => (Icons.calendar_today_rounded, colors.brand),
      NotificationType.payment => (Icons.receipt_long_rounded, colors.success),
      NotificationType.system => (Icons.campaign_rounded, colors.brandSecondary),
    };
  }

  Widget _buildIcon(BuildContext context) {
    final colors = context.colors;
    final (icon, color) = _iconStyle(colors);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
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
