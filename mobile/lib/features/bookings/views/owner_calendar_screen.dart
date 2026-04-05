import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/calendar_model.dart';
import '../../../shared/widgets/calendar_grid_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../calendar/controllers/calendar_controller.dart';

/// Lịch riêng cho chủ nhà — chỉ hiện các căn của chủ nhà.
/// Tap ô = lock/mở phòng.
class OwnerCalendarScreen extends ConsumerStatefulWidget {
  const OwnerCalendarScreen({super.key});

  @override
  ConsumerState<OwnerCalendarScreen> createState() =>
      _OwnerCalendarScreenState();
}

class _OwnerCalendarScreenState
    extends ConsumerState<OwnerCalendarScreen> {
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

    return Scaffold(
      body: Column(
        children: [
          CalendarGradientHeader(
            title: 'Lịch phòng của tôi',
            subtitle: 'Quản lý lịch các căn của bạn',
            actions: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                        onCellTap: (room, date, cell) => _showLockDialog(
                            context, room, date, cell, gridParams!),
                        legendTapHint: 'Tap ô = lock/mở',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockDialog(
    BuildContext context,
    CalendarRoom room,
    DateTime date,
    DayCell cell,
    CalendarGridParams gridParams,
  ) {
    final isAvailable = cell.status == DayCellStatus.available;
    final isHold = cell.status == DayCellStatus.hold;
    final isBooked = cell.status == DayCellStatus.booked;

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    isBooked
                        ? Icons.lock_rounded
                        : isHold
                            ? Icons.lock_clock_rounded
                            : Icons.lock_open_rounded,
                    color: statusColor,
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
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}/${date.month}/${date.year} · $statusLabel',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giá phòng',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  _formatPrice(cell.price),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ocean,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (isAvailable) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleLock(room, date, DayCellStatus.hold, gridParams);
                  },
                  icon: const Icon(Icons.lock_rounded, size: 20),
                  label: Text(
                    'Khoá phòng (Giữ)',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ] else if (isHold) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleLock(
                        room, date, DayCellStatus.available, gridParams);
                  },
                  icon: const Icon(Icons.lock_open_rounded, size: 20),
                  label: Text(
                    'Mở khoá phòng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.coral,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Phòng đã bán — không thể thay đổi trạng thái',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.coral,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLock(
    CalendarRoom room,
    DateTime date,
    DayCellStatus newStatus,
    CalendarGridParams gridParams,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final actions = ref.read(calendarActionsProvider.notifier);

    final success = newStatus == DayCellStatus.hold
        ? await actions.lockRoom(
            roomId: room.id, date: dateStr, gridParams: gridParams)
        : await actions.unlockRoom(
            roomId: room.id, date: dateStr, gridParams: gridParams);

    if (!mounted) return;

    final label =
        newStatus == DayCellStatus.hold ? 'Đã khoá' : 'Đã mở khoá';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '$label phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success
            ? (newStatus == DayCellStatus.hold
                ? AppColors.amber
                : AppColors.emerald)
            : AppColors.coral,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}tr đ/đêm';
    }
    return '${(price / 1000).toInt()}k đ/đêm';
  }
}
