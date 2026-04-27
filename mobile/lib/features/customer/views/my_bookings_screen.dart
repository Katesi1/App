import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/booking_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
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
      builder: (ctx) => AlertDialog(
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
              style:
                  GoogleFonts.beVietnamPro(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(customerBookingProvider.notifier)
                  .cancelBooking(bookingId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã huỷ đặt phòng'
                          : 'Không thể huỷ, thử lại sau',
                    ),
                    backgroundColor:
                        success ? AppColors.emerald : AppColors.coral,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.sm),
                    ),
                    margin: const EdgeInsets.all(AppSpacing.md),
                  ),
                );
              }
            },
            child: Text(
              'Huỷ đặt phòng',
              style: GoogleFonts.beVietnamPro(
                color: AppColors.coral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Booking của tôi',
      selectedIndex: 2,
      body: Column(
        children: [
          // ── Tab bar ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
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
              labelColor: AppColors.ocean,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.ocean,
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final bookingsAsync = ref.watch(myBookingsProvider(widget.status));

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book_outlined,
                    size: 48, color: AppColors.slate),
                const SizedBox(height: 12),
                Text(
                  'Chưa có booking nào',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.ocean,
          onRefresh: () async =>
              ref.invalidate(myBookingsProvider(widget.status)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (_, i) => _MyBookingCard(
              booking: bookings[i],
              index: i,
              onCancel: widget.onCancel,
            ),
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
              style: GoogleFonts.beVietnamPro(color: AppColors.coral),
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

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final statusColor = AppHelpers.bookingStatusColor(booking.status.value);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
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
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  booking.propertyName,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Dates
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _DateInfo(
                  label: 'Nhận phòng',
                  date: _formatDate(booking.checkinDate),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.slate),
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
                        color: AppColors.ocean,
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
                    foregroundColor: AppColors.coral,
                    side: const BorderSide(color: AppColors.coral),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}
