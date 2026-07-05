import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/calendar_model.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/calendar_grid_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../properties/controllers/property_controller.dart';

/// Owner-only calendar — shows only owner's properties (Bearer token).
/// OWNER/SALE see their own properties, ADMIN sees all.
/// Tap cell = lock/unlock room.
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

  // Local override: key = "${roomId}_${yyyy-MM-dd}" → manually marked sold.
  final Set<String> _manualSoldKeys = {};

  // Cache of last successfully rendered grid — keeps UI when navigating to
  // a new week/month while fetching, avoiding loading indicator flash.
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

  /// Maps PropertyCategory → API type param (null = all).
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
      isPublic: false, // management — uses /calendar/grid with Bearer token
    );

    final gridAsync = ref.watch(calendarGridProvider(gridParams));
    final user = ref.watch(currentUserProvider);
    // Tải sẵn danh sách phòng để gate share biết khi owner chưa có phòng nào.
    if (user?.isOwner ?? false) {
      ref.watch(homestayListProvider(false));
    }

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        children: [
          CalendarGradientHeader(
            title: 'Lịch phòng của tôi',
            subtitle: 'Quản lý lịch các căn của bạn',
            showBack: true,
            actions: [
              // Chỉ OWNER mới có lịch phòng công khai để chia sẻ qua Zalo.
              if (user != null && user.isOwner)
                IconButton(
                  onPressed: () => _openShareSheet(user),
                  icon:
                      const Icon(Icons.ios_share_rounded, color: Colors.white),
                  tooltip: 'Chia sẻ lịch phòng qua Zalo',
                ),
            ],
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(calendarGridProvider(gridParams));
                await ref.read(calendarGridProvider(gridParams).future);
              },
              child: _buildGridBody(gridAsync, gridParams, colors),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders grid with smooth UX when navigating weeks/months:
  /// - **Has data**: cache `_lastRooms`, render with AnimatedSwitcher fade transition
  /// - **Loading + has cache**: show old grid + dim spinner overlay (no white flash)
  /// - **Loading + no cache**: full LoadingWidget
  /// - **Error**: ErrorStateWidget
  Widget _buildGridBody(
    AsyncValue<CalendarGrid> gridAsync,
    CalendarGridParams gridParams,
    AppColorScheme colors,
  ) {
    // Animation key — changes on navigate (date range) or view mode switch.
    final animKey = ValueKey(
      '${_viewMode.name}_${gridParams.startDate}_${gridParams.endDate}',
    );

    return gridAsync.when(
      // Cold start: never loaded → full loading.
      loading: () {
        if (_lastRooms == null) return const LoadingWidget();
        // Has cached data → show old grid + dim overlay.
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
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              EmptyStateWidget(
                icon: Icons.calendar_today_outlined,
                message: 'Không có phòng nào',
              ),
            ],
          );
        }
        // Cache for next navigation.
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
        // Slight slide + fade — "carousel" feel between weeks/months.
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

  /// Shows old grid + dim spinner overlay while fetching new data.
  /// Avoids white flash during network wait.
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                // Sold — can only be unlocked.
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
          status: 1, // HOLD
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

  String _formatPrice(double price) =>
      '${AppHelpers.formatPriceCompact(price)} đ/đêm';

  // ─── Chia sẻ lịch phòng qua Zalo ──────────────────────────────────────────

  /// Lý do chưa thể chia sẻ (null = đủ điều kiện). Web sale filter theo
  /// entitlement (§4.1) → owner chưa đủ điều kiện thì link share sẽ trả 404.
  String? _shareBlockReason(UserModel user) {
    if (!user.isKycVerified) {
      return 'Hoàn tất KYC để chia sẻ lịch phòng';
    }
    if (!(user.isSubscriptionActive || user.isInTrial)) {
      return 'Cần gói dịch vụ đang hoạt động để chia sẻ lịch phòng';
    }
    // Chỉ chặn khi đã biết chắc owner không có phòng nào (list đã load).
    final count = ref.read(homestayListProvider(false)).valueOrNull?.length;
    if (count == 0) {
      return 'Tạo phòng trước khi chia sẻ';
    }
    return null;
  }

  void _openShareSheet(UserModel user) {
    final reason = _shareBlockReason(user);
    if (reason != null) {
      AppSnackBar.info(context, reason);
      return;
    }
    final url = AppConstants.zaloCalendarUrl(user.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _ShareCalendarSheet(
        url: url,
        onShare: (origin) => _doShareNative(url, origin),
        onCopy: () => _copyLink(url),
        onPreview: () => _openPreview(url),
      ),
    );
  }

  Future<void> _doShareNative(String url, Rect? sharePositionOrigin) async {
    await Share.share(
      'Lịch phòng của tôi tại Halong24h: $url',
      subject: 'Lịch phòng Halong24h',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) AppSnackBar.success(context, 'Đã copy link');
  }

  Future<void> _openPreview(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      AppSnackBar.error(context, 'Không mở được link');
    }
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

// ─── Share calendar bottom sheet ───────────────────────────────────────────────
class _ShareCalendarSheet extends StatelessWidget {
  final String url;
  final ValueChanged<Rect?> onShare;
  final VoidCallback onCopy;
  final VoidCallback onPreview;

  const _ShareCalendarSheet({
    required this.url,
    required this.onShare,
    required this.onCopy,
    required this.onPreview,
  });

  /// iPad cần `sharePositionOrigin` để neo popover của share sheet.
  static Rect? _rectFromContext(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chia sẻ lịch phòng qua Zalo',
            style: GoogleFonts.beVietnamPro(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gửi link này vào nhóm Zalo — khách & nhân viên bấm vào để xem '
            'lịch trống, giá phòng và gọi cho bạn (không cần cài app).',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Link preview box.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 18, color: colors.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Primary: native share sheet.
          Builder(
            builder: (btnCtx) => SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final origin = _rectFromContext(btnCtx);
                  Navigator.pop(context);
                  onShare(origin);
                },
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  'Chia sẻ',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary: copy + preview.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCopy();
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: Text(
                    'Copy link',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: colors.borderDefault),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onPreview();
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(
                    'Mở thử',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: colors.borderDefault),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
