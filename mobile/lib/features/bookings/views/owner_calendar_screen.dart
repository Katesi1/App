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

/// Lịch riêng cho chủ nhà — chỉ hiện các căn của chủ nhà (Bearer token).
/// OWNER/SALE thấy property của mình, ADMIN thấy tất cả.
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
  DateTime _weekStart = _mondayOf(DateTime.now());
  DateTime _monthStart = DateTime(DateTime.now().year, DateTime.now().month);

  // Local override: key = "${roomId}_${yyyy-MM-dd}" → đã bán thủ công
  final Set<String> _manualSoldKeys = {};

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

  /// Map PropertyCategory → API type param
  int get _typeParam => switch (_category) {
        PropertyCategory.villa => 0,
        PropertyCategory.homestay => 1,
        PropertyCategory.hotel => 2,
      };

  List<CalendarRoom> _mapProperties(List<CalendarRoomRow> rows) {
    return rows.map((row) {
      final cells = <DateTime, DayCell>{};
      for (final day in row.days) {
        final dt = DateTime.parse(day.date);
        final key = DateTime(dt.year, dt.month, dt.day);
        final soldKey = '${row.id}_${day.date}';
        final apiStatus = _mapStatus(day.status);
        cells[key] = DayCell(
          price: day.price,
          status: _manualSoldKeys.contains(soldKey)
              ? DayCellStatus.booked
              : apiStatus,
        );
      }
      return CalendarRoom(id: row.id, code: row.code, dayCells: cells);
    }).toList();
  }

  DayCellStatus _mapStatus(CalendarDayStatus s) => switch (s) {
        CalendarDayStatus.available => DayCellStatus.available,
        CalendarDayStatus.hold => DayCellStatus.hold,
        CalendarDayStatus.booked => DayCellStatus.booked,
        CalendarDayStatus.locked => DayCellStatus.locked,
      };

  @override
  Widget build(BuildContext context) {
    final gridParams = CalendarGridParams(
      startDate: _startDate,
      endDate: _endDate,
      type: _typeParam,
      isPublic: false, // management — dùng /calendar/grid với Bearer token
    );

    final gridAsync = ref.watch(calendarGridProvider(gridParams));

    return Scaffold(
      body: Column(
        children: [
          CalendarGradientHeader(
            title: 'Lịch phòng của tôi',
            subtitle: 'Quản lý lịch các căn của bạn',
            showBack: true,
          ),

          CalendarViewModeToggle(
            viewMode: _viewMode,
            onChanged: (mode) => setState(() => _viewMode = mode),
          ),

          CalendarCategoryTabs(
            selected: _category,
            onChanged: (cat) => setState(() => _category = cat),
          ),

          CalendarDateNavigation(
            viewMode: _viewMode,
            weekStart: _weekStart,
            monthStart: _monthStart,
            onPrevious: () => _navigate(-1),
            onNext: () => _navigate(1),
          ),

          Expanded(
            child: gridAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(calendarGridProvider(gridParams)),
              ),
              data: (grid) {
                final rooms = _mapProperties(grid.properties);
                if (rooms.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.calendar_today_outlined,
                    message: 'Không có phòng nào',
                  );
                }
                return CalendarGridWidget(
                  rooms: rooms,
                  viewMode: _viewMode,
                  weekStart: _weekStart,
                  monthStart: _monthStart,
                  onCellTap: (room, date, cell) => _showLockDialog(
                      context, room, date, cell, gridParams),
                  legendTapHint: 'Tap ô = lock/mở',
                );
              },
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
    final isLocked = cell.status == DayCellStatus.locked;

    final statusLabel = switch (cell.status) {
      DayCellStatus.available => 'Trống',
      DayCellStatus.booked => 'Đã bán',
      DayCellStatus.hold => 'Đang giữ',
      DayCellStatus.locked => 'Đã khoá',
    };
    final statusColor = switch (cell.status) {
      DayCellStatus.available => AppColors.emerald,
      DayCellStatus.booked => AppColors.coral,
      DayCellStatus.hold => AppColors.amber,
      DayCellStatus.locked => AppColors.slate,
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
                        ? Icons.sell_rounded
                        : isHold
                            ? Icons.lock_clock_rounded
                            : isLocked
                                ? Icons.lock_rounded
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
              // Khoá ngày
              _ActionBtn(
                icon: Icons.lock_rounded,
                label: 'Khoá ngày',
                sub: 'Không cho khách đặt ngày này',
                color: AppColors.slate,
                onTap: () {
                  Navigator.pop(ctx);
                  _doLock(room, date, gridParams);
                },
              ),
              const SizedBox(height: 10),
              // Giữ chỗ
              _ActionBtn(
                icon: Icons.lock_clock_rounded,
                label: 'Giữ chỗ',
                sub: 'Tạm khoá, chưa xác nhận',
                color: AppColors.amber,
                onTap: () {
                  Navigator.pop(ctx);
                  _doHold(room, date, gridParams);
                },
              ),
              const SizedBox(height: 10),
              // Đánh dấu đã bán
              _ActionBtn(
                icon: Icons.sell_rounded,
                label: 'Đánh dấu đã bán',
                sub: 'Xác nhận phòng đã có khách',
                color: AppColors.coral,
                onTap: () {
                  Navigator.pop(ctx);
                  _markSold(room, date, gridParams);
                },
              ),
            ] else if (isHold) ...[
              // Mở khoá
              _ActionBtn(
                icon: Icons.lock_open_rounded,
                label: 'Mở khoá phòng',
                sub: 'Trả về trạng thái trống',
                color: AppColors.emerald,
                onTap: () {
                  Navigator.pop(ctx);
                  _doUnlock(room, date, gridParams);
                },
              ),
              const SizedBox(height: 10),
              // Chuyển sang đã bán
              _ActionBtn(
                icon: Icons.sell_rounded,
                label: 'Đánh dấu đã bán',
                sub: 'Xác nhận phòng đã có khách',
                color: AppColors.coral,
                onTap: () {
                  Navigator.pop(ctx);
                  _markSold(room, date, gridParams);
                },
              ),
            ] else if (isLocked) ...[
              // Mở khoá
              _ActionBtn(
                icon: Icons.lock_open_rounded,
                label: 'Mở khoá ngày',
                sub: 'Cho phép khách đặt lại ngày này',
                color: AppColors.emerald,
                onTap: () {
                  Navigator.pop(ctx);
                  _doUnlock(room, date, gridParams);
                },
              ),
            ] else ...[
              // Đã bán — chỉ có thể mở lại
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.coral.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sell_rounded,
                        color: AppColors.coral, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Phòng đã bán',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.coral,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _ActionBtn(
                icon: Icons.lock_open_rounded,
                label: 'Mở khoá phòng',
                sub: 'Trả về trạng thái trống',
                color: AppColors.emerald,
                onTap: () {
                  Navigator.pop(ctx);
                  _doUnlock(room, date, gridParams);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _doLock(
    CalendarRoom room,
    DateTime date,
    CalendarGridParams gridParams,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final success = await ref
        .read(calendarActionsProvider.notifier)
        .lockRoom(
          propertyId: room.id,
          date: dateStr,
          gridParams: gridParams,
          status: 0, // LOCKED
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã khoá phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? AppColors.slate : AppColors.coral,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _doHold(
    CalendarRoom room,
    DateTime date,
    CalendarGridParams gridParams,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final success = await ref
        .read(calendarActionsProvider.notifier)
        .lockRoom(
          propertyId: room.id,
          date: dateStr,
          gridParams: gridParams,
          status: 1, // BOOKED (giữ chỗ)
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã giữ chỗ phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? AppColors.amber : AppColors.coral,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _doUnlock(
    CalendarRoom room,
    DateTime date,
    CalendarGridParams gridParams,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final success = await ref
        .read(calendarActionsProvider.notifier)
        .unlockRoom(
          propertyId: room.id,
          date: dateStr,
          gridParams: gridParams,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã mở khoá phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? AppColors.emerald : AppColors.coral,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markSold(
    CalendarRoom room,
    DateTime date,
    CalendarGridParams gridParams,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final success = await ref
        .read(calendarActionsProvider.notifier)
        .markAsSold(propertyId: room.id, date: dateStr, gridParams: gridParams);

    if (!mounted) return;
    if (success) {
      setState(() => _manualSoldKeys.add('${room.id}_$dateStr'));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã đánh dấu đã bán phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? AppColors.coral : AppColors.muted,
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

// ─── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      sub,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
