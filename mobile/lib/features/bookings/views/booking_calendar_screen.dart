import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/calendar_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/calendar_grid_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../calendar/controllers/calendar_controller.dart';

/// Lịch tổng — dành cho tất cả user xem.
/// Tap ô → mở modal liên hệ admin qua Zalo.
class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState
    extends ConsumerState<BookingCalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.weekly;
  PropertyCategory _category = PropertyCategory.villa;
  int _selectedGroupIndex = 0;
  DateTime _weekStart = _mondayOf(DateTime.now());
  DateTime _monthStart = DateTime(DateTime.now().year, DateTime.now().month);

  static DateTime _mondayOf(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  void _navigate(int direction) {
    setState(() {
      if (_viewMode == CalendarViewMode.weekly) {
        _weekStart = _weekStart.add(Duration(days: 7 * direction));
      } else {
        _monthStart = DateTime(
          _monthStart.year,
          _monthStart.month + direction,
        );
      }
    });
  }

  String get _startDate => DateFormat('yyyy-MM-dd').format(
        _viewMode == CalendarViewMode.weekly ? _weekStart : _monthStart,
      );

  String get _endDate {
    if (_viewMode == CalendarViewMode.weekly) {
      return DateFormat('yyyy-MM-dd')
          .format(_weekStart.add(const Duration(days: 6)));
    }
    final lastDay = DateTime(_monthStart.year, _monthStart.month + 1, 0);
    return DateFormat('yyyy-MM-dd').format(lastDay);
  }

  List<CalendarPropertyGroup> _filterGroups(
      List<CalendarPropertyGroup> all) {
    return all
        .where((g) =>
            (g.category ?? '').toLowerCase() ==
            _category.name.toLowerCase())
        .toList();
  }

  List<CalendarRoom> _mapRooms(List<CalendarRoomRow> rows) {
    return rows.map((row) {
      final cells = <DateTime, DayCell>{};
      for (final day in row.days) {
        final dt = DateTime.parse(day.date);
        final key = DateTime(dt.year, dt.month, dt.day);
        cells[key] = DayCell(
          price: day.price,
          status: _mapStatus(day.status),
        );
      }
      return CalendarRoom(id: row.id, code: row.code, dayCells: cells);
    }).toList();
  }

  DayCellStatus _mapStatus(CalendarDayStatus s) => switch (s) {
        CalendarDayStatus.available => DayCellStatus.available,
        CalendarDayStatus.hold => DayCellStatus.hold,
        CalendarDayStatus.booked => DayCellStatus.booked,
      };

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(calendarPropertyGroupsProvider(null));
    final adminContact = ref.watch(adminContactProvider).valueOrNull;

    final allGroups = groupsAsync.valueOrNull ?? [];
    final filtered = _filterGroups(allGroups);
    final safeIndex = filtered.isEmpty
        ? 0
        : _selectedGroupIndex.clamp(0, filtered.length - 1);

    final gridParams = filtered.isNotEmpty
        ? CalendarGridParams(
            propertyGroupId: filtered[safeIndex].id,
            startDate: _startDate,
            endDate: _endDate,
          )
        : null;

    final gridAsync = gridParams != null
        ? ref.watch(calendarGridProvider(gridParams))
        : const AsyncValue<CalendarGrid>.loading();

    final stubGroups = filtered
        .map((g) => PropertyGroup(
              id: g.id,
              name: g.name,
              category: PropertyCategory.villa,
              rooms: const [],
            ))
        .toList();

    return AppScaffold(
      title: '',
      selectedIndex: 2,
      showAppBar: false,
      body: Column(
        children: [
          CalendarGradientHeader(
            title: 'Lịch Booking',
            subtitle: 'Xem lịch đặt phòng tổng hợp',
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded, color: Colors.white),
              ),
            ],
          ),

          CalendarViewModeToggle(
            viewMode: _viewMode,
            onChanged: (mode) => setState(() => _viewMode = mode),
          ),

          CalendarCategoryTabs(
            selected: _category,
            onChanged: (cat) => setState(() {
              _category = cat;
              _selectedGroupIndex = 0;
            }),
          ),

          if (stubGroups.isNotEmpty)
            CalendarSubCategoryChips(
              groups: stubGroups,
              selectedIndex: safeIndex,
              onChanged: (i) => setState(() => _selectedGroupIndex = i),
            ),

          CalendarDateNavigation(
            viewMode: _viewMode,
            weekStart: _weekStart,
            monthStart: _monthStart,
            onPrevious: () => _navigate(-1),
            onNext: () => _navigate(1),
          ),

          Expanded(
            child: groupsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(calendarPropertyGroupsProvider(null)),
              ),
              data: (_) => filtered.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.calendar_today_outlined,
                      message: 'Không có nhóm phòng nào',
                    )
                  : gridAsync.when(
                      loading: () => const LoadingWidget(),
                      error: (e, _) => ErrorStateWidget(
                        message: e.toString().replaceAll('Exception: ', ''),
                        onRetry: () =>
                            ref.invalidate(calendarGridProvider(gridParams!)),
                      ),
                      data: (grid) => CalendarGridWidget(
                        rooms: _mapRooms(grid.rooms),
                        viewMode: _viewMode,
                        weekStart: _weekStart,
                        monthStart: _monthStart,
                        onCellTap: (room, date, cell) =>
                            _showContactModal(
                                context, room, date, cell, adminContact),
                        legendTapHint: 'Tap ô = liên hệ',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactModal(
    BuildContext context,
    CalendarRoom room,
    DateTime date,
    DayCell cell,
    AdminContact? contact,
  ) {
    final statusLabel = switch (cell.status) {
      DayCellStatus.available => 'Trống',
      DayCellStatus.booked => 'Đã bán',
      DayCellStatus.hold => 'Đang giữ',
    };
    final statusColor = switch (cell.status) {
      DayCellStatus.available => AppColors.emerald,
      DayCellStatus.booked => AppColors.coral,
      DayCellStatus.hold => AppColors.amber,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark ? AppColors.darkSurface : Colors.white;
        final titleColor =
            isDark ? AppColors.darkTextPrimary : AppColors.navy;
        final subtitleColor = isDark ? AppColors.darkHint : AppColors.muted;
        final dividerColor = isDark ? AppColors.darkBorder : AppColors.border;
        final dragColor = isDark ? AppColors.darkBorder : AppColors.border;
        final roomIconBg =
            isDark ? AppColors.ocean.withValues(alpha: 0.2) : AppColors.oceanLight;
        final roomIconColor =
            isDark ? AppColors.oceanBright : AppColors.ocean;
        final priceColor = isDark ? AppColors.oceanBright : AppColors.ocean;

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dragColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: roomIconBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: roomIconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng ${room.code}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(height: 1, color: dividerColor),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giá phòng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  Text(
                    _formatPrice(cell.price),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: priceColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openZalo(contact);
                  },
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: Text(
                    'Liên hệ qua Zalo',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.oceanMid : AppColors.oceanDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _callAdmin(contact);
                  },
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  label: Text(
                    'Gọi điện cho Admin',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.oceanBright : AppColors.ocean,
                    side: BorderSide(
                      color: isDark ? AppColors.oceanBright : AppColors.ocean,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}tr đ/đêm';
    }
    return '${(price / 1000).toInt()}k đ/đêm';
  }

  Future<void> _openZalo(AdminContact? contact) async {
    final url =
        contact?.zaloUrl ?? 'https://zalo.me/${contact?.phone ?? ''}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callAdmin(AdminContact? contact) async {
    final phone = contact?.phone ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
