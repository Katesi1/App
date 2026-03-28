import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';

// ─── Mock data models ────────────────────────────────────────────────────────

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

List<PropertyGroup> _generateMockData(PropertyCategory category) {
  final random = Random(category.index * 42);

  final names = switch (category) {
    PropertyCategory.villa => ['Sunferia', 'Harborbay', 'Grandbay'],
    PropertyCategory.homestay => ['Hạ Long View', 'Bãi Cháy House', 'Tuần Châu Stay'],
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
      final code = '$prefix${random.nextInt(9) + 1}-${(random.nextInt(40) + 1).toString().padLeft(2, '0')}';
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

      rooms.add(CalendarRoom(id: '${groupId}_$i', code: code, dayCells: dayCells));
    }

    return PropertyGroup(
      id: groupId,
      name: entry.value,
      category: category,
      rooms: rooms,
    );
  }).toList();
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState
    extends ConsumerState<BookingCalendarScreen>
    with SingleTickerProviderStateMixin {
  CalendarViewMode _viewMode = CalendarViewMode.weekly;
  PropertyCategory _category = PropertyCategory.villa;
  int _selectedGroupIndex = 0;
  DateTime _weekStart = _mondayOf(DateTime.now());
  DateTime _monthStart = DateTime(DateTime.now().year, DateTime.now().month);

  late final Map<PropertyCategory, List<PropertyGroup>> _mockData;
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  static DateTime _mondayOf(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  @override
  void initState() {
    super.initState();
    _mockData = {
      for (final cat in PropertyCategory.values) cat: _generateMockData(cat),
    };
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  List<PropertyGroup> get _currentGroups => _mockData[_category]!;
  PropertyGroup get _currentGroup => _currentGroups[_selectedGroupIndex];

  List<DateTime> get _visibleDates {
    if (_viewMode == CalendarViewMode.weekly) {
      return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    }
    final daysInMonth = DateUtils.getDaysInMonth(
      _monthStart.year,
      _monthStart.month,
    );
    return List.generate(
      daysInMonth,
      (i) => DateTime(_monthStart.year, _monthStart.month, i + 1),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: '',
      selectedIndex: 2,
      showAppBar: false,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(isDark),

          // ── View mode toggle ──
          _buildViewModeToggle(),

          // ── Category tabs ──
          _buildCategoryTabs(),

          // ── Sub-category chips ──
          _buildSubCategoryChips(),

          // ── Date navigation ──
          _buildDateNavigation(),

          // ── Grid ──
          Expanded(child: _buildGrid()),

          // ── Legend ──
          _buildLegend(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
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
            child: Text(
              'Lịch Booking',
              style: GoogleFonts.beVietnamPro(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Share functionality
            },
            icon: const Icon(Icons.share_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── View mode toggle ────────────────────────────────────
  Widget _buildViewModeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.slateLight,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          children: [
            _viewModeButton('Theo tuần', CalendarViewMode.weekly),
            _viewModeButton('Theo tháng', CalendarViewMode.monthly),
          ],
        ),
      ),
    );
  }

  Widget _viewModeButton(String label, CalendarViewMode mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
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

  // ── Category tabs ───────────────────────────────────────
  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Row(
        children: PropertyCategory.values.map((cat) {
          final isSelected = _category == cat;
          final label = switch (cat) {
            PropertyCategory.villa => 'Villa',
            PropertyCategory.homestay => 'Homestay',
            PropertyCategory.hotel => 'Khách sạn',
          };
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => setState(() {
                _category = cat;
                _selectedGroupIndex = 0;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.oceanDeep : AppColors.slateLight,
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

  // ── Sub-category chips ──────────────────────────────────
  Widget _buildSubCategoryChips() {
    final groups = _currentGroups;
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
          final isSelected = _selectedGroupIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedGroupIndex = i),
            child: Chip(
              label: Text(groups[i].name),
              labelStyle: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.oceanDeep : AppColors.muted,
              ),
              backgroundColor: isSelected ? AppColors.oceanLight : AppColors.surface,
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

  // ── Date navigation ─────────────────────────────────────
  Widget _buildDateNavigation() {
    final dates = _visibleDates;
    final isWeekly = _viewMode == CalendarViewMode.weekly;
    final label = isWeekly
        ? '${DateFormat('d/M').format(dates.first)} – ${DateFormat('d/M').format(dates.last)}'
        : 'Tháng ${_monthStart.month} · ${_monthStart.year}';

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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigate(-1),
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
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.oceanDeep,
                  size: 22,
                ),
              ),
            ),
          ),
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
                  'Năm ${dates.first.year}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigate(1),
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
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.oceanDeep,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid (synced scroll) ────────────────────────────────
  Widget _buildGrid() {
    final dates = _visibleDates;
    final rooms = _currentGroup.rooms;

    const roomColWidth = 64.0;
    const cellWidth = 54.0;
    const cellHeight = 50.0;
    const headerHeight = 44.0;
    final gridWidth = dates.length * cellWidth;

    // Build date header row (used inside horizontal scroll)
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

    // Build one room row
    Widget roomRow(CalendarRoom room) {
      return Row(
        children: dates.map((date) {
          final key = DateTime(date.year, date.month, date.day);
          final cell = room.dayCells[key];
          return _buildCell(
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
        // ── Sticky date header row ──
        Row(
          children: [
            // Top-left corner: "Căn" label
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
            // Date headers (scroll horizontally in sync)
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: gridWidth,
                  child: dateHeaders(),
                ),
              ),
            ),
          ],
        ),

        // ── Room rows (vertical + horizontal sync) ──
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
              // Scrollable grid (linked scroll both axes)
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Sync horizontal header with grid
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.axis == Axis.horizontal) {
                      _horizontalController
                          .jumpTo(notification.metrics.pixels);
                    }
                    // Sync vertical room column with grid
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.axis == Axis.vertical) {
                      _verticalController
                          .jumpTo(notification.metrics.pixels);
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
    DayCell? cell,
    double width,
    double height,
    bool isWeekend,
  ) {
    if (cell == null) {
      return SizedBox(width: width, height: height);
    }

    final priceLabel = _formatShortPrice(cell.price);
    final dotColor = switch (cell.status) {
      DayCellStatus.available => AppColors.emerald,
      DayCellStatus.booked => AppColors.coral,
      DayCellStatus.hold => AppColors.amber,
    };

    final bgColor = switch (cell.status) {
      DayCellStatus.booked => AppColors.coralLight,
      DayCellStatus.hold => AppColors.amberLight,
      DayCellStatus.available =>
        isWeekend ? AppColors.goldLight : Colors.transparent,
    };

    return GestureDetector(
      onTap: () {
        // TODO: lock/unlock room
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
            right: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              priceLabel,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cell.status == DayCellStatus.booked
                    ? AppColors.coral
                    : cell.status == DayCellStatus.hold
                        ? AppColors.brownDark
                        : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Legend ──────────────────────────────────────────────
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
          _legendItem(AppColors.emerald, 'Trống'),
          const SizedBox(width: AppSpacing.lg),
          _legendItem(AppColors.coral, 'Đã bán'),
          const SizedBox(width: AppSpacing.lg),
          _legendItem(AppColors.amber, 'Giữ'),
          const SizedBox(width: AppSpacing.lg),
          Text(
            'Tap ô = lock/mở',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
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

  // ── Helpers ─────────────────────────────────────────────
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
