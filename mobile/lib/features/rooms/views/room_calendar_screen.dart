import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/booking_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../bookings/controllers/booking_controller.dart';

class RoomCalendarScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomCalendarScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomCalendarScreen> createState() => _RoomCalendarScreenState();
}

class _RoomCalendarScreenState extends ConsumerState<RoomCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final params = CalendarParams(
      roomId: widget.roomId,
      year: _focusedDay.year,
      month: _focusedDay.month,
    );
    final calendarAsync = ref.watch(calendarProvider(params));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(calendarProvider(params)),
          ),
        ],
      ),
      body: calendarAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(calendarProvider(params)),
        ),
        data: (bookings) => Column(
          children: [
            // ── Legend ────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm, horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LegendDot(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderColor: colors.primary,
                      label: 'Hôm nay'),
                  _LegendDot(
                      color: AppColors.hold.withValues(alpha: 0.25),
                      borderColor: AppColors.hold,
                      label: 'Đang giữ'),
                  _LegendDot(
                      color: AppColors.confirmed.withValues(alpha: 0.25),
                      borderColor: AppColors.confirmed,
                      label: 'Đã đặt'),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Calendar ──────────────────────────────────────────────
            TableCalendar<CalendarBooking>(
              firstDay: DateTime.now().subtract(const Duration(days: 90)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Tháng',
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left_rounded, color: colors.primary),
                rightChevronIcon:
                    Icon(Icons.chevron_right_rounded, color: colors.primary),
                headerPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                weekendStyle: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary),
                ),
                todayTextStyle: GoogleFonts.beVietnamPro(
                    color: colors.primary, fontWeight: FontWeight.w700),
                selectedDecoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.beVietnamPro(
                    color: colors.onPrimary, fontWeight: FontWeight.w700),
                defaultTextStyle: GoogleFonts.beVietnamPro(color: colors.onSurface),
                weekendTextStyle: GoogleFonts.beVietnamPro(
                    color: colors.primary.withValues(alpha: 0.8)),
                outsideDaysVisible: false,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final booking = _bookingForDay(bookings, day);
                  if (booking == null) return null;
                  final isHold = booking.status == BookingStatus.hold;
                  final color = isHold ? AppColors.hold : AppColors.confirmed;

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: color.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: GoogleFonts.beVietnamPro(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
              eventLoader: (day) =>
                  bookings.where((b) => b.coversDate(day)).toList(),
              onPageChanged: (focusedDay) =>
                  setState(() => _focusedDay = focusedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                final booking = _bookingForDay(bookings, selectedDay);
                if (booking != null) {
                  _showBookingSheet(context, booking);
                }
              },
            ),

            // ── Booking list ──────────────────────────────────────────
            const Divider(height: 1),
            Expanded(
              child: bookings.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.event_available_rounded,
                      message: 'Tháng này còn trống',
                      subMessage: 'Không có booking nào trong tháng này',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _BookingTile(
                        booking: bookings[i],
                        onTap: () => _showBookingSheet(context, bookings[i]),
                      )
                          .animate(delay: Duration(milliseconds: i * 50))
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.05, end: 0),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  CalendarBooking? _bookingForDay(
      List<CalendarBooking> bookings, DateTime day) {
    for (final b in bookings) {
      if (b.coversDate(day)) return b;
    }
    return null;
  }

  void _showBookingSheet(BuildContext context, CalendarBooking booking) {
    final fmt = DateFormat('dd/MM/yyyy');
    final isHold = booking.status == BookingStatus.hold;
    final statusColor = isHold ? AppColors.hold : AppColors.confirmed;
    final nights = booking.checkoutDate.difference(booking.checkinDate).inDays;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Status row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    booking.status.label,
                    style: GoogleFonts.beVietnamPro(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isHold && booking.holdRemainingSeconds > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.timer_outlined,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 3),
                  Text(
                    'Còn ${(booking.holdRemainingSeconds / 60).ceil()} phút',
                    style: GoogleFonts.beVietnamPro(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            if (booking.customerName != null)
              _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Khách hàng',
                  value: booking.customerName!),
            _InfoRow(
                icon: Icons.login_rounded,
                label: 'Check-in',
                value: fmt.format(booking.checkinDate)),
            _InfoRow(
                icon: Icons.logout_rounded,
                label: 'Check-out',
                value: fmt.format(booking.checkoutDate)),
            _InfoRow(
                icon: Icons.nights_stay_outlined,
                label: 'Số đêm',
                value: '$nights đêm'),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;
  const _LegendDot(
      {required this.color, required this.borderColor, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: borderColor, width: 1.5),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      );
}

class _BookingTile extends StatelessWidget {
  final CalendarBooking booking;
  final VoidCallback? onTap;
  const _BookingTile({required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final isHold = booking.status == BookingStatus.hold;
    final color = isHold ? AppColors.hold : AppColors.confirmed;
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Status bar
            Container(width: 4, height: 64, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? 'Chưa có tên khách',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fmt.format(booking.checkinDate)} → ${fmt.format(booking.checkoutDate)}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  booking.status.label,
                  style: GoogleFonts.beVietnamPro(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
