import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ─── Shared data models ──────────────────────────────────────────────────────

enum CalendarViewMode { weekly, monthly }

enum PropertyCategory { villa, homestay, hotel }

class PropertyGroup {
  final String id;
  final String name;
  final PropertyCategory category;
  final List<CalendarRoom> rooms;

  const PropertyGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.rooms,
  });
}

class CalendarRoom {
  final String id;
  final String code;
  final Map<DateTime, DayCell> dayCells;

  const CalendarRoom({
    required this.id,
    required this.code,
    required this.dayCells,
  });
}

enum DayCellStatus { available, booked, hold }

class DayCell {
  final double price;
  final DayCellStatus status;

  const DayCell({required this.price, required this.status});
}

// ─── Mock data generator ─────────────────────────────────────────────────────

List<PropertyGroup> generateMockCalendarData(PropertyCategory category) {
  final random = Random(category.index * 42);

  final names = switch (category) {
    PropertyCategory.villa => ['Sunferia', 'Harborbay', 'Grandbay'],
    PropertyCategory.homestay => [
        'Hạ Long View',
        'Bãi Cháy House',
        'Tuần Châu Stay',
      ],
    PropertyCategory.hotel => ['Grand Palace', 'Ocean Resort', 'Bay Hotel'],
  };

  final roomPrefixes = switch (category) {
    PropertyCategory.villa => ['C', 'M'],
    PropertyCategory.homestay => ['H', 'P'],
    PropertyCategory.hotel => ['R', 'S'],
  };

  return names.asMap().entries.map((entry) {
    final groupId = '${category.name}_${entry.key}';
    final rooms = <CalendarRoom>[];

    for (var i = 0; i < 8 + random.nextInt(5); i++) {
      final prefix = roomPrefixes[random.nextInt(roomPrefixes.length)];
      final code =
          '$prefix${random.nextInt(9) + 1}-${(random.nextInt(40) + 1).toString().padLeft(2, '0')}';
      final basePrice = (random.nextInt(5) + 5) * 1000000.0;

      final dayCells = <DateTime, DayCell>{};
      final now = DateTime.now();
      for (var d = -30; d < 60; d++) {
        final date = DateTime(now.year, now.month, now.day + d);
        final isWeekend = date.weekday == 6 || date.weekday == 7;
        final price = isWeekend ? basePrice * 1.8 : basePrice;

        final statusRoll = random.nextDouble();
        final status = statusRoll < 0.12
            ? DayCellStatus.booked
            : statusRoll < 0.2
                ? DayCellStatus.hold
                : DayCellStatus.available;

        dayCells[date] = DayCell(price: price, status: status);
      }

      rooms.add(
        CalendarRoom(id: '${groupId}_$i', code: code, dayCells: dayCells),
      );
    }

    return PropertyGroup(
      id: groupId,
      name: entry.value,
      category: category,
      rooms: rooms,
    );
  }).toList();
}

// ─── Callbacks ───────────────────────────────────────────────────────────────

typedef CellTapCallback = void Function(
  CalendarRoom room,
  DateTime date,
  DayCell cell,
);

// ─── Calendar Grid Widget ────────────────────────────────────────────────────

class CalendarGridWidget extends StatefulWidget {
  final List<CalendarRoom> rooms;
  final CalendarViewMode viewMode;
  final DateTime weekStart;
  final DateTime monthStart;
  final CellTapCallback? onCellTap;
  final String legendTapHint;

  const CalendarGridWidget({
    super.key,
    required this.rooms,
    required this.viewMode,
    required this.weekStart,
    required this.monthStart,
    this.onCellTap,
    this.legendTapHint = 'Tap ô = lock/mở',
  });

  @override
  State<CalendarGridWidget> createState() => _CalendarGridWidgetState();
}

class _CalendarGridWidgetState extends State<CalendarGridWidget> {
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  List<DateTime> get _visibleDates {
    if (widget.viewMode == CalendarViewMode.weekly) {
      return List.generate(
        7,
        (i) => widget.weekStart.add(Duration(days: i)),
      );
    }
    final daysInMonth = DateUtils.getDaysInMonth(
      widget.monthStart.year,
      widget.monthStart.month,
    );
    return List.generate(
      daysInMonth,
      (i) => DateTime(
        widget.monthStart.year,
        widget.monthStart.month,
        i + 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildGrid()),
        _buildLegend(),
      ],
    );
  }

  Widget _buildGrid() {
    final dates = _visibleDates;
    final rooms = widget.rooms;

    const roomColWidth = 64.0;
    const cellWidth = 54.0;
    const cellHeight = 50.0;
    const headerHeight = 44.0;
    final gridWidth = dates.length * cellWidth;

    Widget dateHeaders() {
      return Row(
        children: dates.map((date) {
          final isWeekend = date.weekday == 6 || date.weekday == 7;
          final isSaturday = date.weekday == 6;
          final dowLabel = _dowLabel(date.weekday);
          return Container(
            width: cellWidth,
            height: headerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWeekend
                  ? AppColors.goldLight.withValues(alpha: 0.5)
                  : Colors.transparent,
              border: const Border(
                bottom: BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dowLabel,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSaturday
                        ? AppColors.oceanMid
                        : isWeekend
                            ? AppColors.coral
                            : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${date.day}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSaturday
                        ? AppColors.oceanMid
                        : isWeekend
                            ? AppColors.coral
                            : AppColors.ink,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    Widget roomRow(CalendarRoom room) {
      return Row(
        children: dates.map((date) {
          final key = DateTime(date.year, date.month, date.day);
          final cell = room.dayCells[key];
          return _buildCell(
            room,
            date,
            cell,
            cellWidth,
            cellHeight,
            date.weekday == 6 || date.weekday == 7,
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        // Sticky date header
        Row(
          children: [
            Container(
              width: roomColWidth,
              height: headerHeight,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.oceanPale,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1.5),
                  right: BorderSide(color: AppColors.border),
                ),
              ),
              child: Text(
                'Căn',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.oceanDeep,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(width: gridWidth, child: dateHeaders()),
              ),
            ),
          ],
        ),

        // Room rows
        Expanded(
          child: Row(
            children: [
              // Fixed room name column
              SizedBox(
                width: roomColWidth,
                child: ListView.builder(
                  controller: _verticalController,
                  padding: EdgeInsets.zero,
                  itemCount: rooms.length,
                  itemExtent: cellHeight,
                  itemBuilder: (_, i) => Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? Colors.transparent
                          : AppColors.slateLight.withValues(alpha: 0.3),
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                        right: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Text(
                      rooms[i].code,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ocean,
                      ),
                    ),
                  ),
                ),
              ),
              // Scrollable grid
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      if (notification.metrics.axis == Axis.horizontal) {
                        _horizontalController.jumpTo(
                          notification.metrics.pixels,
                        );
                      }
                      if (notification.metrics.axis == Axis.vertical) {
                        _verticalController.jumpTo(
                          notification.metrics.pixels,
                        );
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: gridWidth,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: rooms.length,
                        itemExtent: cellHeight,
                        itemBuilder: (_, i) => roomRow(rooms[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    CalendarRoom room,
    DateTime date,
    DayCell? cell,
    double width,
    double height,
    bool isWeekend,
  ) {
    if (cell == null) {
      return _calendarCellShell(
        width: width,
        height: height,
        bgColor: AppColors.slateLight.withValues(alpha: 0.25),
        child: Text(
          '-',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      );
    }

    final bgColor = switch (cell.status) {
      DayCellStatus.booked => AppColors.coralLight,
      DayCellStatus.hold => AppColors.amberLight,
      DayCellStatus.available =>
        isWeekend ? AppColors.goldLight : Colors.transparent,
    };

    final Widget statusChild = switch (cell.status) {
      DayCellStatus.available => Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '-',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1,
                color: AppColors.emerald,
              ),
            ),
            if (cell.price > 0) ...[
              const SizedBox(height: 2),
              Text(
                _formatShortPrice(cell.price),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      DayCellStatus.hold => Icon(
          Icons.lock_rounded,
          size: 18,
          color: AppColors.brownDark,
        ),
      DayCellStatus.booked => Text(
          '×',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1,
            color: AppColors.coral,
          ),
        ),
    };

    return GestureDetector(
      onTap: widget.onCellTap != null
          ? () => widget.onCellTap!(room, date, cell)
          : null,
      child: _calendarCellShell(
        width: width,
        height: height,
        bgColor: bgColor,
        child: statusChild,
      ),
    );
  }

  Widget _calendarCellShell({
    required double width,
    required double height,
    required Color bgColor,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
          right: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: child,
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendSymbol(
            child: Text(
              '-',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
            label: 'Trống',
          ),
          const SizedBox(width: AppSpacing.md),
          _buildLegendSymbol(
            child: Icon(
              Icons.lock_rounded,
              size: 14,
              color: AppColors.brownDark,
            ),
            label: 'Giữ chỗ',
          ),
          const SizedBox(width: AppSpacing.md),
          _buildLegendSymbol(
            child: Text(
              '×',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.coral,
              ),
            ),
            label: 'Đã đặt',
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              widget.legendTapHint,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: AppColors.muted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendSymbol({
    required Widget child,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 18, height: 18, child: Center(child: child)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  String _dowLabel(int weekday) => switch (weekday) {
        DateTime.monday => 'T2',
        DateTime.tuesday => 'T3',
        DateTime.wednesday => 'T4',
        DateTime.thursday => 'T5',
        DateTime.friday => 'T6',
        DateTime.saturday => 'T7',
        DateTime.sunday => 'CN',
        _ => '',
      };

  String _formatShortPrice(double price) {
    if (price >= 1000000) {
      final tr = price / 1000000;
      if (tr == tr.roundToDouble()) {
        return '${tr.toInt()}tr';
      }
      return '${tr.toStringAsFixed(0)}tr';
    }
    return '${(price / 1000).toInt()}k';
  }
}

// ─── Shared UI components ────────────────────────────────────────────────────

class CalendarViewModeToggle extends StatelessWidget {
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onChanged;

  const CalendarViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.slateLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: [
            _button('Theo tuần', CalendarViewMode.weekly),
            _button('Theo tháng', CalendarViewMode.monthly),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, CalendarViewMode mode) {
    final isSelected = viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.oceanDeep : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class CalendarDateNavigation extends StatelessWidget {
  final CalendarViewMode viewMode;
  final DateTime weekStart;
  final DateTime monthStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const CalendarDateNavigation({
    super.key,
    required this.viewMode,
    required this.weekStart,
    required this.monthStart,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isWeekly = viewMode == CalendarViewMode.weekly;
    final dates = isWeekly
        ? [weekStart, weekStart.add(const Duration(days: 6))]
        : [monthStart];
    final label = isWeekly
        ? '${DateFormat('d/M').format(dates[0])} – ${DateFormat('d/M').format(dates[1])}'
        : 'Tháng ${monthStart.month} · ${monthStart.year}';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.oceanPale,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left_rounded, onPrevious),
          Column(
            children: [
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.oceanDeep,
                ),
              ),
              if (isWeekly)
                Text(
                  'Năm ${weekStart.year}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          _navButton(Icons.chevron_right_rounded, onNext),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.oceanDeep, size: 22),
        ),
      ),
    );
  }
}

class CalendarCategoryTabs extends StatelessWidget {
  final PropertyCategory selected;
  final ValueChanged<PropertyCategory> onChanged;

  const CalendarCategoryTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: PropertyCategory.values.map((cat) {
          final isSelected = selected == cat;
          final label = switch (cat) {
            PropertyCategory.villa => 'Villa',
            PropertyCategory.homestay => 'Homestay',
            PropertyCategory.hotel => 'Khách sạn',
          };
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onChanged(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.oceanDeep : AppColors.slateLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CalendarSubCategoryChips extends StatelessWidget {
  final List<PropertyGroup> groups;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const CalendarSubCategoryChips({
    super.key,
    required this.groups,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final isSelected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Chip(
              label: Text(groups[i].name),
              labelStyle: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.oceanDeep : AppColors.muted,
              ),
              backgroundColor:
                  isSelected ? AppColors.oceanLight : AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.ocean : AppColors.border,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }
}

class CalendarGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const CalendarGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 20,
        right: 12,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
