import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/calendar_grid_widget.dart';

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

  late Map<PropertyCategory, List<PropertyGroup>> _mockData;

  static DateTime _mondayOf(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  @override
  void initState() {
    super.initState();
    // TODO: Thay bằng API — lấy chỉ các căn của chủ nhà hiện tại
    _mockData = {
      for (final cat in PropertyCategory.values)
        cat: generateMockCalendarData(cat),
    };
  }

  List<PropertyGroup> get _currentGroups => _mockData[_category]!;
  PropertyGroup get _currentGroup => _currentGroups[_selectedGroupIndex];

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

  void _onCellTap(CalendarRoom room, DateTime date, DayCell cell) {
    _showLockDialog(context, room, date, cell);
  }

  @override
  Widget build(BuildContext context) {
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

          CalendarSubCategoryChips(
            groups: _currentGroups,
            selectedIndex: _selectedGroupIndex,
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
            child: CalendarGridWidget(
              rooms: _currentGroup.rooms,
              viewMode: _viewMode,
              weekStart: _weekStart,
              monthStart: _monthStart,
              onCellTap: _onCellTap,
              legendTapHint: 'Tap ô = lock/mở',
            ),
          ),
        ],
      ),
    );
  }

  // ── Lock / Unlock dialog ────────────────────────────────
  void _showLockDialog(
    BuildContext context,
    CalendarRoom room,
    DateTime date,
    DayCell cell,
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Room info
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

            // Price
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

            // Action buttons
            if (isAvailable) ...[
              // Lock room
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleLock(room, date, DayCellStatus.hold);
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
              // Unlock room
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleLock(room, date, DayCellStatus.available);
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
              // Booked — cannot change
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

  void _toggleLock(CalendarRoom room, DateTime date, DayCellStatus newStatus) {
    // TODO: Gọi API lock/unlock — sau đó invalidate provider để đồng bộ lịch tổng
    final key = DateTime(date.year, date.month, date.day);
    final oldCell = room.dayCells[key];
    if (oldCell == null) return;

    setState(() {
      room.dayCells[key] = DayCell(price: oldCell.price, status: newStatus);
    });

    final label = newStatus == DayCellStatus.hold ? 'Đã khoá' : 'Đã mở khoá';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label phòng ${room.code} ngày ${date.day}/${date.month}'),
          backgroundColor: newStatus == DayCellStatus.hold
              ? AppColors.amber
              : AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      final tr = price / 1000000;
      return '${tr.toStringAsFixed(1)}tr đ/đêm';
    }
    return '${(price / 1000).toInt()}k đ/đêm';
  }
}
