import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/booking_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/booking_controller.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  // null = all
  BookingStatus? _filterStatus;

  static const _filters = <BookingStatus?>[
    null,
    BookingStatus.hold,
    BookingStatus.confirmed,
    BookingStatus.cancelled,
    BookingStatus.noShow,
  ];

  static const _filterLabels = [
    'Tất cả',
    'Đang giữ',
    'Đã đặt',
    'Đã huỷ',
    'Không đến'
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bookingsAsync = ref.watch(bookingListProvider(null));
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: '',
      selectedIndex: 4,
      showAppBar: false,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.jade900, AppColors.jade500],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -50,
                  top: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.jade300.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -40,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold500.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      // /bookings is top-level (entered via bottom nav `context.go`
                      // → empty stack, pop = no-op). Fallback to /dashboard.
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý Booking',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Theo dõi và xử lý đặt phòng',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/front-desk'),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: const Icon(Icons.room_service_outlined,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    _AvatarBtn(
                      userName: user?.name ?? user?.phone ?? '',
                      onTap: () => context.push('/profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Status filter chips ──────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final status = _filters[i];
                final selected = _filterStatus == status;
                final color = _statusColor(status, colors);

                return FilterChip(
                  label: Text(_filterLabels[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => _filterStatus = status),
                  selectedColor: color.withValues(alpha: 0.15),
                  checkmarkColor: color,
                  labelStyle: GoogleFonts.beVietnamPro(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : colors.textPrimary,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: bookingsAsync.when(
              loading: () =>
                  SkeletonList(skeleton: const BookingCardSkeleton(), count: 5),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(bookingListProvider(null)),
              ),
              data: (bookings) {
                final filtered = _filterStatus == null
                    ? bookings
                    : bookings.where((b) => b.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_note_outlined,
                    message: _filterStatus == null
                        ? 'Chưa có booking nào'
                        : 'Không có booking ${_filterLabels[_filters.indexOf(_filterStatus)]}',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(bookingListProvider(null)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _BookingCard(
                      booking: filtered[i],
                      index: i,
                      canManage: user?.canEdit ?? false,
                      onAction: () => ref.invalidate(bookingListProvider(null)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BookingStatus? status, AppColorScheme colors) {
    switch (status) {
      case BookingStatus.hold:
        return colors.warning;
      case BookingStatus.confirmed:
        return colors.success;
      case BookingStatus.cancelled:
        return colors.error;
      case BookingStatus.noShow:
        return colors.warning;
      default:
        return colors.brand;
    }
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────
class _BookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final int index;
  final bool canManage;
  final VoidCallback onAction;

  const _BookingCard({
    required this.booking,
    required this.index,
    required this.canManage,
    required this.onAction,
  });

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _actionLoading = false;

  String _formatPrice(double amount) {
    final formatted = amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted đ';
  }

  Color _statusColorOf(AppColorScheme colors) {
    switch (widget.booking.status) {
      case BookingStatus.hold:
        return colors.warning;
      case BookingStatus.confirmed:
        return colors.success;
      case BookingStatus.cancelled:
        return colors.error;
      case BookingStatus.noShow:
        return colors.warning;
      default:
        return colors.textTertiary;
    }
  }

  Future<void> _confirm() async {
    setState(() => _actionLoading = true);
    final success = await ref
        .read(bookingActionsProvider.notifier)
        .confirm(widget.booking.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (success) {
      AppSnackBar.success(context, 'Xác nhận booking thành công');
      widget.onAction();
    } else {
      AppSnackBar.error(context, 'Không thể xác nhận, thử lại sau');
    }
  }

  Future<void> _cancel() async {
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận huỷ',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn huỷ booking này?',
            style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: colors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Huỷ booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _actionLoading = true);
    final success = await ref
        .read(bookingActionsProvider.notifier)
        .cancel(widget.booking.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (success) {
      AppSnackBar.success(context, 'Đã huỷ booking');
      widget.onAction();
    } else {
      AppSnackBar.error(context, 'Không thể huỷ, thử lại sau');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booking = widget.booking;
    final fmt = DateFormat('dd/MM/yyyy');
    final isHold = booking.status == BookingStatus.hold;
    final statusColor = _statusColorOf(colors);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: colors.bgSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left status bar ─────────────────────────────────────
            Container(width: 4, color: statusColor),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.propertyName,
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                                alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            booking.status.label,
                            style: GoogleFonts.beVietnamPro(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Homestay
                    Text(
                      booking.propertyName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Dates
                    Row(
                      children: [
                        Icon(Icons.date_range_rounded,
                            size: 14, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${fmt.format(booking.checkinDate)} → ${fmt.format(booking.checkoutDate)}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '(${booking.nights} đêm)',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: colors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Customer
                    if (booking.customerName != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14, color: colors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            booking.customerName!,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                          if (booking.customerPhone != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              booking.customerPhone!,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Price + guest count row
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (booking.depositAmount != null &&
                            booking.depositAmount! > 0) ...[
                          Icon(Icons.payments_outlined,
                              size: 14, color: colors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            _formatPrice(booking.depositAmount!),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.brand,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Icon(Icons.people_outline_rounded,
                            size: 14, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.guestCount} khách',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Nhắn tin với khách (hội thoại theo booking — realtime).
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.push(
                          '/conversations/by-booking/${booking.id}',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.brand,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16),
                        label: Text('Nhắn tin',
                            style: GoogleFonts.beVietnamPro(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    // Countdown for HOLD
                    if (isHold && booking.holdRemainingSeconds > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.warning
                              .withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: colors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 13, color: colors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Còn ${(booking.holdRemainingSeconds / 60).ceil()} phút',
                              style: GoogleFonts.beVietnamPro(
                                color: colors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Action buttons (for HOLD bookings)
                    if (isHold) ...[
                      const SizedBox(height: AppSpacing.md),
                      _actionLoading
                          ? const Center(
                              child: SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)))
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancel,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.error,
                                      side: BorderSide(color: colors.error),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                    ),
                                    child: Text('Huỷ',
                                        style: GoogleFonts.beVietnamPro(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                ),
                                if (widget.canManage) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _confirm,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                      ),
                                      child: Text('Xác nhận',
                                          style: GoogleFonts.beVietnamPro(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar Button ─────────────────────────────────────────────────────────────
class _AvatarBtn extends StatelessWidget {
  final String userName;
  final VoidCallback onTap;

  const _AvatarBtn({required this.userName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [AppColors.jade300, AppColors.gold500]),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Center(
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
