import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ─── Shared data models ──────────────────────────────────────────────────────

enum CalendarViewMode { weekly, monthly }

enum PropertyCategory { all, villa, homestay, hotel }

class CalendarRoom {
  final String id;
  final String code;
  // SĐT chủ nhà — dùng cho nút Zalo trong modal liên hệ (null = chưa cài).
  final String? ownerPhone;
  final Map<DateTime, DayCell> dayCells;

  const CalendarRoom({
    required this.id,
    required this.code,
    this.ownerPhone,
    required this.dayCells,
  });
}

enum DayCellStatus { available, booked, hold, locked }

class DayCell {
  final double price;
  final DayCellStatus status;

  const DayCell({required this.price, required this.status});
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
  final _headerHorizontalController = ScrollController();
  final _bodyHorizontalController = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Sync header → body
    _headerHorizontalController.addListener(_syncHeaderToBody);
    // Sync body → header
    _bodyHorizontalController.addListener(_syncBodyToHeader);
  }

  void _syncHeaderToBody() {
    if (_isSyncing) return;
    _isSyncing = true;
    if (_bodyHorizontalController.hasClients) {
      _bodyHorizontalController.jumpTo(_headerHorizontalController.offset);
    }
    _isSyncing = false;
  }

  void _syncBodyToHeader() {
    if (_isSyncing) return;
    _isSyncing = true;
    if (_headerHorizontalController.hasClients) {
      _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
    }
    _isSyncing = false;
  }

  @override
  void dispose() {
    _headerHorizontalController.removeListener(_syncHeaderToBody);
    _bodyHorizontalController.removeListener(_syncBodyToHeader);
    _verticalController.dispose();
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(child: _buildGrid(isDark)),
        _buildLegend(isDark),
      ],
    );
  }

  Widget _buildGrid(bool isDark) {
    final dates = _visibleDates;
    final rooms = widget.rooms;

    const roomColWidth = 104.0;
    const cellWidth = 54.0;
    const cellHeight = 50.0;
    const headerHeight = 44.0;
    final gridWidth = dates.length * cellWidth;

    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Widget dateHeaders() {
      return Row(
        children: dates.map((date) {
          final dateKey = DateTime(date.year, date.month, date.day);
          final isToday = dateKey == today;
          final isWeekend = date.weekday == 6 || date.weekday == 7;
          final isSaturday = date.weekday == 6;
          final dowLabel = _dowLabel(date.weekday);
          final weekendBg = isDark
              ? AppColors.gold.withValues(alpha: 0.12)
              : AppColors.goldLight.withValues(alpha: 0.5);

          // Text color — today is always deep ocean, weekend coral/oceanMid.
          final dayColor = isToday
              ? AppColors.ocean
              : isSaturday
                  ? AppColors.oceanMid
                  : isWeekend
                      ? AppColors.coral
                      : isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.ink;

          return Container(
            width: cellWidth,
            height: headerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWeekend ? weekendBg : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1.5),
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
                    color: isToday
                        ? AppColors.ocean
                        : isSaturday
                            ? AppColors.oceanMid
                            : isWeekend
                                ? AppColors.coral
                                : isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                // Today: day number wrapped in ocean circle to stand out.
                isToday
                    ? Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ocean,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ocean.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      )
                    : Text(
                        '${date.day}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: dayColor,
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
            isDark,
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
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkContainer : AppColors.oceanPale,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1.5),
                  right: BorderSide(color: borderColor),
                ),
              ),
              child: Text(
                'Mã căn',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.oceanBright : AppColors.oceanDeep,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? Colors.transparent
                          : isDark
                              ? AppColors.darkContainer.withValues(alpha: 0.4)
                              : AppColors.slateLight.withValues(alpha: 0.3),
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 0.5),
                        right: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text(
                      // Strip prefix "DEMO-" for concise names, e.g.
                      // "DEMO-VILLA-01" → "VILLA-01".
                      rooms[i].code.replaceFirst(
                          RegExp(r'^(DEMO|PROD|TEST)-', caseSensitive: false),
                          ''),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: isDark ? AppColors.oceanBright : AppColors.ocean,
                      ),
                    ),
                  ),
                ),
              ),
              // Scrollable grid
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.axis == Axis.vertical) {
                      _verticalController.jumpTo(
                        notification.metrics.pixels,
                      );
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _bodyHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: gridWidth,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: rooms.length,
                        itemExtent: cellHeight,
                        physics: const BouncingScrollPhysics(),
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
    bool isDark,
  ) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    if (cell == null) {
      return _calendarCellShell(
        width: width,
        height: height,
        bgColor: isDark
            ? AppColors.darkContainer.withValues(alpha: 0.2)
            : AppColors.slateLight.withValues(alpha: 0.25),
        borderColor: borderColor,
        child: Text(
          '-',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkHint : AppColors.muted,
          ),
        ),
      );
    }

    final bgColor = switch (cell.status) {
      DayCellStatus.booked =>
        isDark ? AppColors.coral.withValues(alpha: 0.2) : AppColors.coralLight,
      DayCellStatus.hold =>
        isDark ? AppColors.amber.withValues(alpha: 0.18) : AppColors.amberLight,
      DayCellStatus.locked =>
        isDark ? AppColors.slate.withValues(alpha: 0.25) : AppColors.slateLight,
      DayCellStatus.available => isWeekend
          ? isDark
              ? AppColors.gold.withValues(alpha: 0.1)
              : AppColors.goldLight
          : Colors.transparent,
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
                  color: isDark ? AppColors.darkHint : AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      DayCellStatus.hold => Icon(
          Icons.lock_clock_rounded,
          size: 18,
          color: isDark ? AppColors.amber : AppColors.brownDark,
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
      DayCellStatus.locked => Icon(
          Icons.lock_rounded,
          size: 18,
          color: isDark ? AppColors.slate : AppColors.muted,
        ),
    };

    // Disable tap for past dates.
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isPast = date.isBefore(todayDate);

    return GestureDetector(
      onTap: (widget.onCellTap != null && !isPast)
          ? () => widget.onCellTap!(room, date, cell)
          : null,
      child: Opacity(
        opacity: isPast ? 0.4 : 1.0,
        child: _calendarCellShell(
          width: width,
          height: height,
          bgColor: bgColor,
          borderColor: borderColor,
          child: statusChild,
        ),
      ),
    );
  }

  Widget _calendarCellShell({
    required double width,
    required double height,
    required Color bgColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 0.5),
          right: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: child,
    );
  }

  Widget _buildLegend(bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final hintColor = isDark ? AppColors.darkHint : AppColors.muted;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;
    final lockColor = isDark ? AppColors.amber : AppColors.brownDark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : null,
        border: Border(top: BorderSide(color: borderColor)),
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
            labelColor: labelColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildLegendSymbol(
            child: Icon(Icons.lock_clock_rounded, size: 14, color: lockColor),
            label: 'Giữ chỗ',
            labelColor: labelColor,
          ),
          const SizedBox(width: AppSpacing.sm),
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
            labelColor: labelColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildLegendSymbol(
            child: Icon(
              Icons.lock_rounded,
              size: 14,
              color: isDark ? AppColors.slate : AppColors.muted,
            ),
            label: 'Khoá',
            labelColor: labelColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              widget.legendTapHint,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: hintColor,
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
    required Color labelColor,
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
            color: labelColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          color: isDark ? AppColors.darkContainer : AppColors.slateLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: [
            _button('Theo tuần', CalendarViewMode.weekly, isDark),
            _button('Theo tháng', CalendarViewMode.monthly, isDark),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, CalendarViewMode mode, bool isDark) {
    final isSelected = viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? isDark
                    ? AppColors.oceanMid
                    : AppColors.oceanDeep
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? AppColors.darkHint
                      : AppColors.muted,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        color: isDark ? AppColors.darkContainer : AppColors.oceanPale,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left_rounded, onPrevious, isDark),
          Column(
            children: [
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.oceanDeep,
                ),
              ),
              if (isWeekly)
                Text(
                  'Năm ${weekStart.year}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: isDark ? AppColors.darkHint : AppColors.muted,
                  ),
                ),
            ],
          ),
          _navButton(Icons.chevron_right_rounded, onNext, isDark),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.oceanBright : AppColors.oceanDeep,
            size: 22,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: PropertyCategory.values.map((cat) {
          final isSelected = selected == cat;
          final label = switch (cat) {
            PropertyCategory.all => 'Tất cả',
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
                  color: isSelected
                      ? isDark
                          ? AppColors.oceanMid
                          : AppColors.oceanDeep
                      : isDark
                          ? AppColors.darkContainer
                          : AppColors.slateLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.transparent,
                        ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? AppColors.darkHint
                            : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      ),
    );
  }
}

class CalendarGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;

  const CalendarGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 8,
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
          if (showBack)
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 8, right: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 18),
              ),
            )
          else
            const SizedBox(width: 12),
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
