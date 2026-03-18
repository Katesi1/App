import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/booking_provider.dart';

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
  ];

  static const _filterLabels = ['Tất cả', 'Đang giữ', 'Đã đặt', 'Đã huỷ'];

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingListProvider(null));
    final user = ref.watch(currentUserProvider);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Quản lý Booking',
      selectedIndex: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.invalidate(bookingListProvider),
        ),
      ],
      body: Column(
        children: [
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
                final color = _statusColor(status);

                return FilterChip(
                  label: Text(_filterLabels[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => _filterStatus = status),
                  selectedColor: color.withValues(alpha: 0.15),
                  checkmarkColor: color,
                  labelStyle: GoogleFonts.nunito(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : colors.onSurface,
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
                onRetry: () => ref.invalidate(bookingListProvider),
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
                  onRefresh: () async => ref.invalidate(bookingListProvider),
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
                      onAction: () => ref.invalidate(bookingListProvider),
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

  Color _statusColor(BookingStatus? status) {
    switch (status) {
      case BookingStatus.hold:
        return AppColors.hold;
      case BookingStatus.confirmed:
        return AppColors.confirmed;
      case BookingStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.primary;
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

  Color get _statusColor {
    switch (widget.booking.status) {
      case BookingStatus.hold:
        return AppColors.hold;
      case BookingStatus.confirmed:
        return AppColors.confirmed;
      case BookingStatus.cancelled:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirm() async {
    setState(() => _actionLoading = true);
    final result = await BookingRepository().confirmBooking(widget.booking.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (result.success) {
      AppSnackBar.success(context, 'Xác nhận booking thành công');
      widget.onAction();
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận huỷ',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn huỷ booking này?',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Huỷ booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _actionLoading = true);
    final result = await BookingRepository().cancelBooking(widget.booking.id);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (result.success) {
      AppSnackBar.success(context, 'Đã huỷ booking');
      widget.onAction();
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final fmt = DateFormat('dd/MM/yyyy');
    final isHold = booking.status == BookingStatus.hold;
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: 0.06),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left status bar ─────────────────────────────────────
            Container(width: 4, color: _statusColor),

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
                            booking.roomName,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                                color: _statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            booking.status.label,
                            style: GoogleFonts.nunito(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Homestay
                    Text(
                      booking.homestayName,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Dates
                    Row(
                      children: [
                        Icon(Icons.date_range_rounded,
                            size: 14,
                            color: colors.onSurface.withValues(alpha: 0.45)),
                        const SizedBox(width: 4),
                        Text(
                          '${fmt.format(booking.checkinDate)} → ${fmt.format(booking.checkoutDate)}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '(${booking.nights} đêm)',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: colors.primary,
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
                              size: 14,
                              color: colors.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Text(
                            booking.customerName!,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          if (booking.customerPhone != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              booking.customerPhone!,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Countdown for HOLD
                    if (isHold && booking.holdRemainingSeconds > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 13, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Còn ${(booking.holdRemainingSeconds / 60).ceil()} phút',
                              style: GoogleFonts.nunito(
                                color: AppColors.warning,
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
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                          color: AppColors.error),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                    ),
                                    child: Text('Huỷ',
                                        style: GoogleFonts.nunito(
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
                                        backgroundColor: AppColors.confirmed,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                      ),
                                      child: Text('Xác nhận',
                                          style: GoogleFonts.nunito(
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
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }
}
