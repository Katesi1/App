import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

DateTime _sheetDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _sheetFormatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// Bottom sheet chọn khoảng ngày báo cáo.
class ReportDateRangeSheet extends StatefulWidget {
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const ReportDateRangeSheet({
    super.key,
    this.initialFrom,
    this.initialTo,
  });

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTime? initialFrom,
    DateTime? initialTo,
  }) {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ReportDateRangeSheet(
        initialFrom: initialFrom,
        initialTo: initialTo,
      ),
    );
  }

  @override
  State<ReportDateRangeSheet> createState() => _ReportDateRangeSheetState();
}

class _ReportDateRangeSheetState extends State<ReportDateRangeSheet> {
  late DateTime _today;
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  String? _activePreset;

  @override
  void initState() {
    super.initState();
    _today = _sheetDateOnly(DateTime.now());
    final end =
        widget.initialTo != null ? _sheetDateOnly(widget.initialTo!) : _today;
    final start = widget.initialFrom != null
        ? _sheetDateOnly(widget.initialFrom!)
        : end.subtract(const Duration(days: 29));
    final safeEnd = end.isAfter(_today) ? _today : end;
    final safeStart = start.isAfter(safeEnd)
        ? safeEnd.subtract(const Duration(days: 29))
        : start;
    _rangeStart = safeStart;
    _rangeEnd = safeEnd;
    _focusedDay = safeEnd;
    _activePreset = '30';
  }

  void _applyPreset(String key, int days) {
    final end = _today;
    setState(() {
      _activePreset = key;
      _rangeEnd = end;
      _rangeStart = end.subtract(Duration(days: days - 1));
      _focusedDay = end;
    });
  }

  void _applyThisMonth() {
    final end = _today;
    setState(() {
      _activePreset = 'month';
      _rangeStart = DateTime(end.year, end.month, 1);
      _rangeEnd = end;
      _focusedDay = end;
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focused) {
    setState(() {
      _activePreset = null;
      _rangeStart = start;
      _rangeEnd = end ?? start;
      _focusedDay = focused;
    });
  }

  bool get _canApply =>
      _rangeStart != null &&
      _rangeEnd != null &&
      !_rangeStart!.isAfter(_rangeEnd!);

  int get _dayCount {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    return _rangeEnd!.difference(_rangeStart!).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          child: Material(
            color: colors.bgCanvas,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(colors: colors),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        _RangeSummaryCard(
                          from: _rangeStart,
                          to: _rangeEnd,
                          dayCount: _dayCount,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _QuickPresets(
                          activeKey: _activePreset,
                          onDays: _applyPreset,
                          onThisMonth: _applyThisMonth,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _CalendarCard(
                          today: _today,
                          focusedDay: _focusedDay,
                          rangeStart: _rangeStart,
                          rangeEnd: _rangeEnd,
                          onRangeSelected: _onRangeSelected,
                          onPageChanged: (f) =>
                              setState(() => _focusedDay = f),
                        ),
                      ],
                    ),
                  ),
                ),
                _ActionBar(
                  canApply: _canApply,
                  dayCount: _dayCount,
                  onCancel: () => Navigator.of(context).pop(),
                  onApply: () {
                    if (!_canApply) return;
                    Navigator.of(context).pop(
                      DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final AppColorScheme colors;

  const _SheetHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.jade900, AppColors.jade500],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khoảng thời gian',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Chọn ngày bắt đầu và ngày kết thúc',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSummaryCard extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final int dayCount;

  const _RangeSummaryCard({
    required this.from,
    required this.to,
    required this.dayCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasRange = from != null && to != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ĐANG CHỌN',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (hasRange && dayCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '$dayCount ngày',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.brand,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Từ',
                    value: hasRange ? _sheetFormatDate(from!) : '—',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                ),
                Expanded(
                  child: _DateField(
                    label: 'Đến',
                    value: hasRange ? _sheetFormatDate(to!) : '—',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;

  const _DateField({
    required this.label,
    required this.value,
  });

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
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _QuickPresets extends StatelessWidget {
  final String? activeKey;
  final void Function(String key, int days) onDays;
  final VoidCallback onThisMonth;

  const _QuickPresets({
    required this.activeKey,
    required this.onDays,
    required this.onThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [
      ('7', 7, '7 ngày'),
      ('30', 30, '30 ngày'),
      ('90', 90, '90 ngày'),
      ('month', 0, 'Tháng này'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        final isActive = activeKey == p.$1;
        return _PresetChip(
          label: p.$3,
          isActive: isActive,
          onTap: () {
            if (p.$1 == 'month') {
              onThisMonth();
            } else {
              onDays(p.$1, p.$2);
            }
          },
        );
      }).toList(),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? colors.brand : colors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive ? colors.brand : colors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? colors.textOnPrimary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime today;
  final DateTime focusedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final void Function(DateTime? start, DateTime? end, DateTime focused)
      onRangeSelected;
  final ValueChanged<DateTime> onPageChanged;

  const _CalendarCard({
    required this.today,
    required this.focusedDay,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onRangeSelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rangeColor = colors.brand.withValues(alpha: 0.14);
    final endpointColor = colors.brand;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TableCalendar<void>(
        locale: 'vi',
        firstDay: DateTime(2020, 1, 1),
        lastDay: today,
        focusedDay: focusedDay,
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        rangeSelectionMode: RangeSelectionMode.toggledOn,
        startingDayOfWeek: StartingDayOfWeek.monday,
        sixWeekMonthsEnforced: false,
        daysOfWeekHeight: 28,
        rowHeight: 40,
        availableGestures: AvailableGestures.horizontalSwipe,
        onRangeSelected: onRangeSelected,
        onPageChanged: onPageChanged,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: const EdgeInsets.symmetric(vertical: 6),
          titleTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: colors.brand,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: colors.brand,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
          ),
          weekendStyle: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.brandWarm,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          rangeHighlightColor: rangeColor,
          withinRangeDecoration: const BoxDecoration(),
          rangeStartDecoration: BoxDecoration(
            color: endpointColor,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: endpointColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: colors.brand.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          todayTextStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            color: colors.brand,
          ),
          rangeStartTextStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            color: colors.textOnPrimary,
          ),
          rangeEndTextStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            color: colors.textOnPrimary,
          ),
          withinRangeTextStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w600,
            color: colors.brand,
          ),
          defaultTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: colors.textPrimary,
          ),
          weekendTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: colors.brandWarm,
          ),
          disabledTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: colors.textDisabled,
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool canApply;
  final int dayCount;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const _ActionBar({
    required this.canApply,
    required this.dayCount,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canApply && dayCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Áp dụng báo cáo $dayCount ngày',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.borderDefault),
                      foregroundColor: colors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: canApply ? onApply : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
