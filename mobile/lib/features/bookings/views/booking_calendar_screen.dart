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
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/booking_controller.dart';

class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState
    extends ConsumerState<BookingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static const _dowLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  @override
  Widget build(BuildContext context) {
    final bookingsAsync =
        ref.watch(bookingListProvider(null));

    return AppScaffold(
      title: '',
      selectedIndex: 2,
      showAppBar: false,
      body: Column(
        children: [
          // ── Gradient header ────────────────────────
          _CalendarHeader(
            focusedDay: _focusedDay,
            onRefresh: () =>
                ref.invalidate(bookingListProvider),
          ),

          // ── Body ──────────────────────────────────
          Expanded(
            child: bookingsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e
                    .toString()
                    .replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(bookingListProvider),
              ),
              data: (bookings) {
                final active = bookings
                    .where((b) =>
                        b.status !=
                        BookingStatus.cancelled)
                    .toList();

                final selectedBookings =
                    _selectedDay == null
                        ? <BookingModel>[]
                        : active
                            .where((b) => _coversDate(
                                b, _selectedDay!))
                            .toList();

                return Column(
                  children: [
                    // ── Calendar ─────────────────────
                    TableCalendar<BookingModel>(
                      firstDay: DateTime.now().subtract(
                          const Duration(days: 365)),
                      lastDay: DateTime.now().add(
                          const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDay),
                      calendarFormat:
                          CalendarFormat.month,
                      startingDayOfWeek:
                          StartingDayOfWeek.monday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Tháng',
                      },
                      rowHeight: 48,
                      daysOfWeekHeight: 36,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextFormatter:
                            (date, locale) =>
                                'Tháng ${date.month}'
                                ' · ${date.year}',
                        titleTextStyle:
                            GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                        leftChevronIcon: Container(
                          padding:
                              const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.slateLight,
                            borderRadius:
                                BorderRadius.circular(
                                    AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                        rightChevronIcon: Container(
                          padding:
                              const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.slateLight,
                            borderRadius:
                                BorderRadius.circular(
                                    AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons
                                .chevron_right_rounded,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                        headerPadding:
                            const EdgeInsets.symmetric(
                                vertical:
                                    AppSpacing.sm),
                      ),
                      daysOfWeekStyle:
                          const DaysOfWeekStyle(
                        dowTextFormatter: null,
                      ),
                      calendarStyle:
                          const CalendarStyle(
                        outsideDaysVisible: false,
                        cellMargin: EdgeInsets.all(3),
                        // Hide default event markers
                        markerSize: 0,
                        markersMaxCount: 0,
                      ),
                      calendarBuilders:
                          CalendarBuilders(
                        // ── Day of week header ──
                        dowBuilder: (context, day) {
                          final idx =
                              (day.weekday - 1) % 7;
                          final isWeekend =
                              day.weekday == 6 ||
                                  day.weekday == 7;
                          return Container(
                            alignment: Alignment.center,
                            child: Text(
                              _dowLabels[idx],
                              style: GoogleFonts
                                  .beVietnamPro(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w700,
                                color: isWeekend
                                    ? AppColors.gold
                                    : AppColors.muted,
                              ),
                            ),
                          );
                        },

                        // ── Today ──
                        todayBuilder:
                            (context, day, focused) {
                          return _buildDayCell(
                            day: day,
                            bgColor:
                                AppColors.oceanDeep,
                            textColor: Colors.white,
                          );
                        },

                        // ── Selected day ──
                        selectedBuilder:
                            (context, day, focused) {
                          return _buildDayCell(
                            day: day,
                            bgColor:
                                AppColors.oceanDeep,
                            textColor: Colors.white,
                          );
                        },

                        // ── Default day ──
                        defaultBuilder:
                            (context, day, focused) {
                          final booking =
                              _bookingForDay(
                                  active, day);
                          final isWeekend =
                              day.weekday == 6 ||
                                  day.weekday == 7;

                          if (booking != null) {
                            return _buildBookingCell(
                              day: day,
                              booking: booking,
                            );
                          }

                          if (isWeekend) {
                            return _buildDayCell(
                              day: day,
                              bgColor:
                                  AppColors.goldLight,
                              textColor:
                                  AppColors.gold,
                            );
                          }

                          return _buildDayCell(
                            day: day,
                            bgColor:
                                Colors.transparent,
                            textColor: AppColors.ink,
                          );
                        },

                        // ── Markers: hide ──
                        markerBuilder:
                            (_, __, ___) =>
                                const SizedBox.shrink(),

                        outsideBuilder:
                            (_, __, ___) =>
                                const SizedBox.shrink(),
                      ),
                      eventLoader: (_) => [],
                      onPageChanged: (focusedDay) =>
                          setState(() =>
                              _focusedDay = focusedDay),
                      onDaySelected:
                          (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                    ),

                    // ── Legend ───────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          _LegendDot(
                            color: AppColors.oceanDeep,
                            label: 'Hôm nay',
                          ),
                          const SizedBox(
                              width: AppSpacing.lg),
                          _LegendDot(
                            color: AppColors.hold,
                            label: 'Đang giữ',
                          ),
                          const SizedBox(
                              width: AppSpacing.lg),
                          _LegendDot(
                            color: AppColors.confirmed,
                            label: 'Đã đặt',
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // ── Booking list ─────────────────
                    Expanded(
                      child: selectedBookings.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons
                                  .event_available_rounded,
                              message: _selectedDay ==
                                      null
                                  ? 'Chọn ngày để xem'
                                      ' booking'
                                  : 'Không có booking'
                                      ' ngày này',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.all(
                                      AppSpacing.md),
                              itemCount:
                                  selectedBookings
                                      .length,
                              separatorBuilder:
                                  (_, __) =>
                                      const SizedBox(
                                          height:
                                              AppSpacing
                                                  .sm),
                              itemBuilder: (_, i) =>
                                  _BookingTile(
                                booking:
                                    selectedBookings[i],
                              )
                                      .animate(
                                          delay: Duration(
                                              milliseconds:
                                                  i *
                                                      50))
                                      .fadeIn(
                                          duration:
                                              250.ms)
                                      .slideY(
                                        begin: 0.05,
                                        end: 0,
                                      ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBookingCell({
    required DateTime day,
    required BookingModel booking,
  }) {
    final isHold =
        booking.status == BookingStatus.hold;
    final bgColor = isHold
        ? AppColors.amberLight
        : AppColors.oceanLight;
    final borderColor = isHold
        ? AppColors.hold.withValues(alpha: 0.5)
        : AppColors.confirmed.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isHold
              ? AppColors.brownDark
              : AppColors.oceanDeep,
        ),
      ),
    );
  }

  bool _coversDate(BookingModel b, DateTime date) {
    final d =
        DateTime(date.year, date.month, date.day);
    final c = DateTime(b.checkinDate.year,
        b.checkinDate.month, b.checkinDate.day);
    final co = DateTime(b.checkoutDate.year,
        b.checkoutDate.month, b.checkoutDate.day);
    return !d.isBefore(c) && d.isBefore(co);
  }

  BookingModel? _bookingForDay(
      List<BookingModel> bookings, DateTime day) {
    for (final b in bookings) {
      if (_coversDate(b, day)) return b;
    }
    return null;
  }
}

// ─── Gradient header (like Dashboard) ──────────────────
class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onRefresh;

  const _CalendarHeader({
    required this.focusedDay,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.4, -1),
          end: const Alignment(0.4, 1),
          colors: isDark
              ? [AppColors.darkGradientStart, AppColors.darkGradientEnd]
              : [AppColors.oceanDeep, AppColors.ocean],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch Booking',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý lịch đặt phòng',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: Colors.white
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legend dot ─────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      );
}

// ─── Booking tile ──────────────────────────────────────
class _BookingTile extends StatelessWidget {
  final BookingModel booking;

  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final isHold =
        booking.status == BookingStatus.hold;
    final color =
        isHold ? AppColors.hold : AppColors.confirmed;
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
              width: 4, height: 64, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.roomName,
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.customerName ?? 'Chưa có tên khách'}'
                    ' · ${fmt.format(booking.checkinDate)}'
                    ' → ${fmt.format(booking.checkoutDate)}',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: colors.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                right: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                    AppRadius.full),
                border: Border.all(
                  color:
                      color.withValues(alpha: 0.4),
                ),
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
    );
  }
}
