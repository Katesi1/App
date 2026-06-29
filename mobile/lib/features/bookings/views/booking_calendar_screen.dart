import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/calendar_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/calendar_grid_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../calendar/controllers/calendar_controller.dart';

/// Public calendar — viewable by all users (no auth required).
/// Tap cell → opens modal to contact admin via Zalo.
class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends ConsumerState<BookingCalendarScreen> {
  CalendarViewMode _viewMode = CalendarViewMode.weekly;
  PropertyCategory _category = PropertyCategory.all;
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
        cells[key] = DayCell(
          price: day.price,
          status: _mapStatus(day.status),
        );
      }
      return CalendarRoom(
        id: row.id,
        code: row.code,
        ownerPhone: row.ownerPhone,
        dayCells: cells,
      );
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
      isPublic: true,
    );

    final gridAsync = ref.watch(calendarGridProvider(gridParams));

    return AppScaffold(
      title: '',
      selectedIndex: 2,
      showAppBar: false,
      body: Column(
        children: [
          CalendarGradientHeader(
            title: 'Lịch Booking',
            subtitle: 'Xem lịch đặt phòng tổng hợp',
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
                onRetry: () => ref.invalidate(calendarGridProvider(gridParams)),
              ),
              data: (grid) {
                final rooms = _mapProperties(grid.properties);
                if (rooms.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.calendar_today_outlined,
                    message: 'Không có phòng nào',
                  );
                }
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
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
                    key: ValueKey(
                        '${_viewMode.name}_${gridParams.startDate}_${gridParams.endDate}'),
                    rooms: rooms,
                    viewMode: _viewMode,
                    weekStart: _weekStart,
                    monthStart: _monthStart,
                    onCellTap: (room, date, cell) =>
                        _showContactModal(context, room, date, cell),
                    legendTapHint: 'Tap ô = liên hệ',
                  ),
                );
              },
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
  ) {
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
                          colors.brand.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: colors.brand,
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
                          '${date.day}/${date.month}/${date.year}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: colors.textSecondary,
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
                      color:
                          statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Zalo = SĐT chủ nhà (room.ownerPhone từ API). Chưa cài →
                    // modal cảnh báo.
                    final phone = room.ownerPhone;
                    if (_hasOwnerPhone(phone)) {
                      _openZalo(phone!);
                    } else {
                      _showOwnerPhoneMissingModal(context);
                    }
                  },
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: Text(
                    'Liên hệ Zalo chủ nhà',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: colors.textOnPrimary,
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
                    _callAdmin();
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
                    foregroundColor: colors.brand,
                    side: BorderSide(color: colors.brand),
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

  /// Chủ nhà đã cài SĐT để liên hệ Zalo chưa?
  bool _hasOwnerPhone(String? phone) =>
      phone != null && phone.trim().isNotEmpty;

  Future<void> _openZalo(String phone) async {
    final uri = Uri.parse('https://zalo.me/${phone.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Gọi tổng đài admin — hotline cố định (KHÁC Zalo chủ nhà).
  Future<void> _callAdmin() async {
    final uri = Uri.parse('tel:${AppConstants.adminHotline}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Cảnh báo khi chủ nhà chưa cài SĐT → không thể liên hệ Zalo. Gợi ý gọi
  /// tổng đài admin thay thế.
  void _showOwnerPhoneMissingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.colors;
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
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_disabled_rounded,
                  color: colors.warning,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chủ nhà chưa cài số điện thoại',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hiện chưa thể liên hệ Zalo với chủ nhà của phòng này. '
                'Bạn có thể gọi tổng đài admin để được hỗ trợ.',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _callAdmin();
                  },
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  label: Text(
                    'Gọi điện cho Admin',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: colors.textOnPrimary,
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
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
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
}
