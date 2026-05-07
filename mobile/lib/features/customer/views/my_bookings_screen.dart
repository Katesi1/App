import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/booking_model.dart';
import '../../../shared/widgets/ai_insight_card.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_strip.dart';
import '../controllers/customer_controller.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // status: null=tất cả, 0=HOLD, 1=CONFIRMED, 2=CANCELLED
  static const _tabs = <(String label, int? status)>[
    ('Tất cả', null),
    ('Đang giữ', 0),
    ('Đã xác nhận', 1),
    ('Đã huỷ', 2),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _cancelBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          title: Text(
            'Huỷ đặt phòng?',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc muốn huỷ đặt phòng này?',
            style: GoogleFonts.beVietnamPro(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Không',
                style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref
                    .read(customerBookingProvider.notifier)
                    .cancelBooking(bookingId);
                if (mounted) {
                  final snackColors = context.colors;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Đã huỷ đặt phòng'
                            : 'Không thể huỷ, thử lại sau',
                      ),
                      backgroundColor:
                          success ? snackColors.success : snackColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      margin: const EdgeInsets.all(AppSpacing.md),
                    ),
                  );
                }
              },
              child: Text(
                'Huỷ đặt phòng',
                style: GoogleFonts.beVietnamPro(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppScaffold(
      title: 'Booking của tôi',
      selectedIndex: 2,
      body: Column(
        children: [
          // ── Tab bar ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.bgSurface,
              border: Border(
                bottom: BorderSide(color: colors.borderDefault),
              ),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              labelColor: colors.brand,
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: colors.brand,
              indicatorWeight: 2.5,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
            ),
          ),

          // ── Tab content ──────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: _tabs.map((tab) {
                return _BookingTab(
                  status: tab.$2,
                  onCancel: _cancelBooking,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Tab ────────────────────────────────────────────────────────────

class _BookingTab extends ConsumerStatefulWidget {
  final int? status;
  final void Function(String id) onCancel;

  const _BookingTab({
    required this.status,
    required this.onCancel,
  });

  @override
  ConsumerState<_BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends ConsumerState<_BookingTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _computeInsight(List<BookingModel> bookings) {
    final pending =
        bookings.where((b) => b.status == BookingStatus.hold).length;
    final now = DateTime.now();
    final upcoming = bookings.where((b) {
      return b.status == BookingStatus.confirmed && b.checkinDate.isAfter(now);
    }).length;

    if (pending > 0) {
      return 'Bạn có $pending booking đang chờ xác nhận. Đặt cọc sớm để giữ chỗ.';
    }
    if (upcoming > 0) {
      return 'Còn $upcoming chuyến sắp tới. Kiểm tra thông tin nhận phòng trước 1 ngày để chuẩn bị tốt nhất.';
    }
    return 'Cảm ơn đã đồng hành cùng Halong24h. Hành trình tốt đẹp tới Hạ Long!';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final bookingsAsync = ref.watch(myBookingsProvider(widget.status));
    final colors = context.colors;

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book_outlined, size: 48, color: colors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  'Chưa có booking nào',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // AI Insight chỉ hiện ở tab "Tất cả" (status null) để tránh spam
        final showInsight = widget.status == null;
        final insightMessage = _computeInsight(bookings);

        return RefreshIndicator(
          color: colors.brand,
          onRefresh: () async =>
              ref.invalidate(myBookingsProvider(widget.status)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length + (showInsight ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (showInsight && i == 0) {
                return AIInsightCard(message: insightMessage);
              }
              final idx = showInsight ? i - 1 : i;
              return _MyBookingCard(
                booking: bookings[idx],
                index: idx,
                onCancel: widget.onCancel,
              );
            },
          ),
        );
      },
      loading: () => SkeletonList(
        skeleton: const BookingCardSkeleton(),
        count: 5,
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.beVietnamPro(color: colors.error),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.invalidate(myBookingsProvider(widget.status)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My Booking Card ────────────────────────────────────────────────────────

class _MyBookingCard extends StatelessWidget {
  final BookingModel booking;
  final int index;
  final void Function(String id) onCancel;

  const _MyBookingCard({
    required this.booking,
    required this.index,
    required this.onCancel,
  });

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  ({IconData icon, String label, String? subtitle, StatusStripVariant variant})
      _stripData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ci = DateTime(booking.checkinDate.year, booking.checkinDate.month,
        booking.checkinDate.day);
    final co = DateTime(booking.checkoutDate.year, booking.checkoutDate.month,
        booking.checkoutDate.day);
    final daysUntil = ci.difference(today).inDays;
    final isOngoing = !today.isBefore(ci) && today.isBefore(co);

    switch (booking.status) {
      case BookingStatus.cancelled:
        return (
          icon: Icons.cancel_outlined,
          label: 'Đã huỷ',
          subtitle: null,
          variant: StatusStripVariant.error,
        );
      case BookingStatus.completed:
        return (
          icon: Icons.check_circle_outline,
          label: 'Đã hoàn tất',
          subtitle: 'Cảm ơn đã chọn Halong24h',
          variant: StatusStripVariant.neutral,
        );
      case BookingStatus.hold:
        return (
          icon: Icons.access_time_rounded,
          label: 'Đang giữ chỗ',
          subtitle: 'Xác nhận sớm để giữ phòng',
          variant: StatusStripVariant.warning,
        );
      case BookingStatus.confirmed:
        if (isOngoing) {
          return (
            icon: Icons.hotel_outlined,
            label: 'Đang ở phòng',
            subtitle: null,
            variant: StatusStripVariant.success,
          );
        }
        if (daysUntil >= 0 && daysUntil <= 3) {
          return (
            icon: Icons.schedule_rounded,
            label: daysUntil == 0
                ? 'Nhận phòng hôm nay'
                : 'Còn $daysUntil ngày nhận phòng',
            subtitle: null,
            variant: StatusStripVariant.brand,
          );
        }
        if (daysUntil > 3) {
          return (
            icon: Icons.event_outlined,
            label: 'Sắp tới: $daysUntil ngày nữa',
            subtitle: null,
            variant: StatusStripVariant.info,
          );
        }
        return (
          icon: Icons.check_circle_outline,
          label: 'Đã hoàn tất',
          subtitle: null,
          variant: StatusStripVariant.neutral,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = AppHelpers.bookingStatusColor(booking.status.value);
    final strip = _stripData();

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status strip — context info ngay top card
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: StatusStrip(
              icon: strip.icon,
              label: strip.label,
              subtitle: strip.subtitle,
              variant: strip.variant,
            ),
          ),
          // Header: room name + status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    booking.propertyName,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    booking.status.label,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Homestay name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  booking.propertyName,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            indent: 16,
            endIndent: 16,
            color: colors.borderSubtle,
          ),

          // Dates
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _DateInfo(
                  label: 'Nhận phòng',
                  date: _formatDate(booking.checkinDate),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: colors.textTertiary),
                ),
                _DateInfo(
                  label: 'Trả phòng',
                  date: _formatDate(booking.checkoutDate),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${booking.nights} đêm',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textBrand,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cancel button (chỉ hiện khi HOLD)
          if (booking.status == BookingStatus.hold)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton(
                  onPressed: () => onCancel(booking.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Huỷ đặt phòng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

// ─── Date Info ──────────────────────────────────────────────────────────────

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;

  const _DateInfo({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
