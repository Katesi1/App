import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/calendar_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/calendar_grid_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../calendar/controllers/calendar_controller.dart';

/// Lịch tổng — dành cho tất cả user xem (public, không cần auth).
/// Tap ô → mở modal liên hệ admin qua Zalo.
class BookingCalendarScreen extends ConsumerStatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends ConsumerState<BookingCalendarScreen> {
  final _screenshotController = ScreenshotController();
  bool _isSharing = false;

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
        final dt = DateTime.tryParse(day.date);
        if (dt == null) continue;
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
    final adminContact = ref.watch(adminContactProvider).valueOrNull;

    return AppScaffold(
      title: '',
      selectedIndex: 2,
      showAppBar: false,
      body: Column(
        children: [
          CalendarGradientHeader(
            title: 'Lịch Booking',
            subtitle: 'Xem lịch đặt phòng tổng hợp',
            actions: [
              _isSharing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _shareCalendar,
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Chia sẻ lịch',
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
                return Screenshot(
                  controller: _screenshotController,
                  child: AnimatedSwitcher(
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
                        child: SlideTransition(
                            position: offset, child: child),
                      );
                    },
                    child: CalendarGridWidget(
                      key: ValueKey(
                          '${_viewMode.name}_${gridParams.startDate}_${gridParams.endDate}'),
                      rooms: rooms,
                      viewMode: _viewMode,
                      weekStart: _weekStart,
                      monthStart: _monthStart,
                      onCellTap: (room, date, cell) => _showContactModal(
                          context, room, date, cell, adminContact),
                      legendTapHint: 'Tap ô = liên hệ',
                    ),
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
    AdminContact? contact,
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
                    _openZalo(contact);
                  },
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  label: Text(
                    'Liên hệ qua Zalo',
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
                    _callAdmin(contact);
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

  Future<void> _openZalo(AdminContact? contact) async {
    if (contact == null) return;
    final zaloUrl = contact.zaloUrl;
    final url = (zaloUrl != null && zaloUrl.isNotEmpty)
        ? zaloUrl
        : 'https://zalo.me/${contact.phone}';
    if (contact.phone.isEmpty && (zaloUrl == null || zaloUrl.isEmpty)) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callAdmin(AdminContact? contact) async {
    final phone = contact?.phone ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String get _rangeLabel {
    if (_viewMode == CalendarViewMode.weekly) {
      final end = _weekStart.add(const Duration(days: 6));
      return '${_weekStart.day}/${_weekStart.month} – ${end.day}/${end.month}/${end.year}';
    }
    return 'Tháng ${_monthStart.month}/${_monthStart.year}';
  }

  void _shareCalendar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
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
                'Chia sẻ lịch booking',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _rangeLabel,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.borderDefault),
              const SizedBox(height: 16),
              _ShareOption(
                icon: Icons.image_rounded,
                iconColor: colors.brandLight,
                iconBg:
                    colors.brandLight.withValues(alpha: isDark ? 0.18 : 0.12),
                title: 'Chia sẻ ảnh chụp lịch',
                subtitle: 'Gửi ngay qua Zalo, nhắn tin — ai cũng xem được',
                onTap: () {
                  Navigator.pop(ctx);
                  _doShareImage();
                },
              ),
              const SizedBox(height: 12),
              _ShareOption(
                icon: Icons.download_rounded,
                iconColor: colors.brand,
                iconBg: colors.brand.withValues(alpha: isDark ? 0.18 : 0.10),
                title: 'Gửi link app & lịch',
                subtitle: 'Nhân viên mở link để tải app và xem lịch realtime',
                onTap: () {
                  Navigator.pop(ctx);
                  _doShareAppLink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _doShareImage() async {
    setState(() => _isSharing = true);
    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 2.0);
      if (imageBytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lich_booking.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Lịch Booking Halong24h',
        text: '📅 Lịch đặt phòng $_rangeLabel – Halong24h',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _doShareAppLink() async {
    final message = '📅 Halong24h — Quản lý phòng & lịch booking\n\n'
        'Tải ứng dụng để xem lịch đặt phòng, nhận thông báo và quản lý homestay:\n\n'
        '🤖 Android: ${AppConstants.playStoreUrl}\n'
        '🍎 iOS: ${AppConstants.appStoreUrl}';

    await Share.share(
      message,
      subject: 'Tải ứng dụng Halong24h',
    );
  }
}

// ─── Share option tile ───────────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.bgSurfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
