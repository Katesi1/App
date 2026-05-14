import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/theme/app_color_scheme.dart';
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

class _OwnerCalendarScreenState extends ConsumerState<OwnerCalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.weekly;
  PropertyCategory _category = PropertyCategory.all;
  DateTime _weekStart = _mondayOf(DateTime.now());
  DateTime _monthStart = DateTime(DateTime.now().year, DateTime.now().month);

  // Local override: key = "${roomId}_${yyyy-MM-dd}" → đã bán thủ công
  final Set<String> _manualSoldKeys = {};

  // Cache grid cuối cùng render thành công — dùng để giữ UI khi navigate
  // sang tuần/tháng mới đang fetch, tránh flash loading indicator.
  List<CalendarRoom>? _lastRooms;

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

  /// Map PropertyCategory → API type param (null = tất cả)
  int? get _typeParam => switch (_category) {
        PropertyCategory.all => null,
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
    final colors = context.colors;
    final gridParams = CalendarGridParams(
      startDate: _startDate,
      endDate: _endDate,
      type: _typeParam,
      isPublic: false, // management — dùng /calendar/grid với Bearer token
    );

    final gridAsync = ref.watch(calendarGridProvider(gridParams));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
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
            child: _buildGridBody(gridAsync, gridParams, colors),
          ),
        ],
      ),
    );
  }

  /// Render grid với UX smooth khi navigate tuần/tháng:
  /// - **Có data**: cache `_lastRooms`, render grid với AnimatedSwitcher fade transition
  /// - **Loading + có cache**: hiện grid cũ + spinner mờ overlay (không flash trắng)
  /// - **Loading + chưa cache**: LoadingWidget full
  /// - **Error**: ErrorStateWidget
  Widget _buildGridBody(
    AsyncValue<CalendarGrid> gridAsync,
    CalendarGridParams gridParams,
    AppColorScheme colors,
  ) {
    // Animation key — đổi khi navigate (date range) hoặc switch view mode.
    final animKey = ValueKey(
      '${_viewMode.name}_${gridParams.startDate}_${gridParams.endDate}',
    );

    return gridAsync.when(
      // Cold start: chưa từng load → full loading
      loading: () {
        if (_lastRooms == null) return const LoadingWidget();
        // Đã có data cũ → hiện grid cũ + overlay mờ
        return _stackWithOverlay(
          child: _buildGrid(_lastRooms!, gridParams, animKey),
          colors: colors,
        );
      },
      error: (e, _) {
        if (_lastRooms != null) {
          return _stackWithOverlay(
            child: _buildGrid(_lastRooms!, gridParams, animKey),
            colors: colors,
            errorMessage: e.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(calendarGridProvider(gridParams)),
          );
        }
        return ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(calendarGridProvider(gridParams)),
        );
      },
      data: (grid) {
        final rooms = _mapProperties(grid.properties);
        if (rooms.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.calendar_today_outlined,
            message: 'Không có phòng nào',
          );
        }
        // Cache cho lần navigate sau.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _lastRooms = rooms);
        });
        return _buildGrid(rooms, gridParams, animKey);
      },
    );
  }

  Widget _buildGrid(
    List<CalendarRoom> rooms,
    CalendarGridParams gridParams,
    Key animKey,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // Slide nhẹ + fade — feel "carousel" giữa các tuần/tháng.
        final offset = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: CalendarGridWidget(
        key: animKey,
        rooms: rooms,
        viewMode: _viewMode,
        weekStart: _weekStart,
        monthStart: _monthStart,
        onCellTap: (room, date, cell) =>
            _showLockDialog(context, room, date, cell, gridParams),
        legendTapHint: 'Tap ô = lock/mở',
      ),
    );
  }

  /// Hiện grid cũ + spinner mờ overlay khi đang fetch data mới.
  /// Tránh flash white trong lúc chờ network.
  Widget _stackWithOverlay({
    required Widget child,
    required AppColorScheme colors,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return Stack(
      children: [
        Opacity(opacity: 0.55, child: IgnorePointer(child: child)),
        const Positioned.fill(
          child: Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
        if (errorMessage != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.md,
            child: Center(
              child: Material(
                color: colors.error.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Tải lại',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        final statusLabel = switch (cell.status) {
          DayCellStatus.available => 'Trống',
          DayCellStatus.booked => 'Đã bán',
          DayCellStatus.hold => 'Đang giữ',
          DayCellStatus.locked => 'Đã khoá',
        };
        final statusColor = switch (cell.status) {
          DayCellStatus.available => colors.success,
          DayCellStatus.booked => colors.error,
          DayCellStatus.hold => colors.warning,
          DayCellStatus.locked => colors.textTertiary,
        };

        return Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
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
                  color: colors.borderDefault,
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
                      color:
                          statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
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
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}/${date.month}/${date.year} · $statusLabel',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.borderDefault),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giá phòng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatPrice(cell.price),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textBrand,
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
                  color: colors.textTertiary,
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
                  color: colors.warning,
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
                  color: colors.error,
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
                  color: colors.success,
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
                  color: colors.error,
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
                  color: colors.success,
                  onTap: () {
                    Navigator.pop(ctx);
                    _doUnlock(room, date, gridParams);
                  },
                ),
              ] else ...[
                // Đã bán — chỉ có thể mở lại
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.errorBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border:
                        Border.all(color: colors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sell_rounded, color: colors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Phòng đã bán',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: colors.error,
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
                  color: colors.success,
                  onTap: () {
                    Navigator.pop(ctx);
                    _doUnlock(room, date, gridParams);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _doLock(
    CalendarRoom room,
    DateTime date,
    CalendarGridParams gridParams,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final success = await ref.read(calendarActionsProvider.notifier).lockRoom(
          propertyId: room.id,
          date: dateStr,
          gridParams: gridParams,
          status: 0, // LOCKED
        );

    if (!mounted) return;
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã khoá phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? colors.textTertiary : colors.error,
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
    final success = await ref.read(calendarActionsProvider.notifier).lockRoom(
          propertyId: room.id,
          date: dateStr,
          gridParams: gridParams,
          status: 1, // HOLD (giữ chỗ)
        );

    if (!mounted) return;
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã giữ chỗ phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? colors.warning : colors.error,
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
    final success = await ref.read(calendarActionsProvider.notifier).unlockRoom(
          propertyId: room.id,
          date: dateStr,
          gridParams: gridParams,
        );

    if (!mounted) return;
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã mở khoá phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? colors.success : colors.error,
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
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã đánh dấu đã bán phòng ${room.code} ngày ${date.day}/${date.month}'
              : 'Có lỗi xảy ra, vui lòng thử lại',
        ),
        backgroundColor: success ? colors.error : colors.textSecondary,
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
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: color.withValues(alpha: isDark ? 0.14 : 0.08),
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
                  color: color.withValues(alpha: isDark ? 0.18 : 0.12),
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
                        color: colors.textSecondary,
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
