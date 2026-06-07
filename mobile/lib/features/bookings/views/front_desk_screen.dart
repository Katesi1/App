import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/booking_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/booking_controller.dart';

/// Front-desk view — today's arrivals (nhận phòng) and departures (trả phòng).
///
/// Backend has no dedicated "checked-in/out" status (only HOLD → CONFIRMED →
/// CANCELLED/COMPLETED), so this screen groups bookings by `checkinDate` /
/// `checkoutDate` for a picked day and surfaces the real available actions:
/// call the guest, and confirm a still-held arrival.
final _deskDateProvider = StateProvider.autoDispose<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

enum _DeskTab { arrivals, departures }

class FrontDeskScreen extends ConsumerStatefulWidget {
  const FrontDeskScreen({super.key, this.initialTab});

  /// 'departures' opens the check-out tab; anything else (default) opens
  /// arrivals (check-in).
  final String? initialTab;

  @override
  ConsumerState<FrontDeskScreen> createState() => _FrontDeskScreenState();
}

class _FrontDeskScreenState extends ConsumerState<FrontDeskScreen> {
  late _DeskTab _tab = widget.initialTab == 'departures'
      ? _DeskTab.departures
      : _DeskTab.arrivals;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = ref.watch(_deskDateProvider);
    final bookingsAsync = ref.watch(bookingListProvider(null));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        children: [
          _Header(date: date),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(bookingListProvider(null)),
              ),
              data: (all) {
                // Exclude cancelled — they're not front-desk relevant.
                final active = all
                    .where((b) => b.status != BookingStatus.cancelled)
                    .toList();
                final arrivals = active
                    .where((b) => _sameDay(b.checkinDate, date))
                    .toList()
                  ..sort((a, b) => a.checkinDate.compareTo(b.checkinDate));
                final departures = active
                    .where((b) => _sameDay(b.checkoutDate, date))
                    .toList()
                  ..sort((a, b) => a.checkoutDate.compareTo(b.checkoutDate));
                final list = _tab == _DeskTab.arrivals ? arrivals : departures;

                return Column(
                  children: [
                    _TabBar(
                      tab: _tab,
                      arrivalCount: arrivals.length,
                      departureCount: departures.length,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: colors.brand,
                        onRefresh: () async =>
                            ref.invalidate(bookingListProvider(null)),
                        child: list.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  EmptyStateWidget(
                                    icon: _tab == _DeskTab.arrivals
                                        ? Icons.login_rounded
                                        : Icons.logout_rounded,
                                    message: _tab == _DeskTab.arrivals
                                        ? 'Không có khách nhận phòng ngày này'
                                        : 'Không có khách trả phòng ngày này',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 32),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) => _BookingCard(
                                  booking: list[i],
                                  tab: _tab,
                                  onConfirm: () => _confirm(list[i]),
                                  onCall: () => _call(list[i]),
                                )
                                    .animate(delay: (i * 40).ms)
                                    .fadeIn(duration: 220.ms)
                                    .slideY(begin: 0.06, end: 0),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(BookingModel b) async {
    final phone = b.customerPhone;
    if (phone == null || phone.isEmpty) {
      _toast('Khách chưa có số điện thoại');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      _toast('Không mở được trình gọi điện');
    }
  }

  Future<void> _confirm(BookingModel b) async {
    final ok = await ref
        .read(bookingActionsProvider.notifier)
        .confirm(b.id, propertyId: b.propertyId);
    if (!mounted) return;
    _toast(
      ok ? 'Đã xác nhận nhận phòng' : 'Xác nhận thất bại, thử lại',
      error: !ok,
    );
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? context.colors.error : context.colors.brand,
      ),
    );
  }
}

// ─── Header (gradient + date navigator) ─────────────────────────────────────

class _Header extends ConsumerWidget {
  final DateTime date;
  const _Header({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    void shift(int days) {
      ref.read(_deskDateProvider.notifier).state =
          DateTime(date.year, date.month, date.day + days);
    }

    Future<void> pick() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2),
        helpText: 'Chọn ngày',
      );
      if (picked != null) {
        ref.read(_deskDateProvider.notifier).state =
            DateTime(picked.year, picked.month, picked.day);
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 8,
        right: 12,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.darkBg, AppColors.darkBorder]
              : const [AppColors.jade500, Color(0xFF1B7E94)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lễ tân',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Nhận & trả phòng theo ngày',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: pick,
                icon: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Date navigator pill.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _NavArrow(
                    icon: Icons.chevron_left_rounded, onTap: () => shift(-1)),
                Expanded(
                  child: GestureDetector(
                    onTap: pick,
                    child: Column(
                      children: [
                        Text(
                          AppHelpers.vietnameseDayOfWeek(date.weekday),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          '${_two(date.day)}/${_two(date.month)}/${date.year}'
                          '${isToday ? '  ·  Hôm nay' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavArrow(
                    icon: Icons.chevron_right_rounded, onTap: () => shift(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── Segmented tab bar ──────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final _DeskTab tab;
  final int arrivalCount;
  final int departureCount;
  final ValueChanged<_DeskTab> onChanged;

  const _TabBar({
    required this.tab,
    required this.arrivalCount,
    required this.departureCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Nhận phòng',
            icon: Icons.login_rounded,
            count: arrivalCount,
            selected: tab == _DeskTab.arrivals,
            color: colors.success,
            onTap: () => onChanged(_DeskTab.arrivals),
          ),
          _Segment(
            label: 'Trả phòng',
            icon: Icons.logout_rounded,
            count: departureCount,
            selected: tab == _DeskTab.departures,
            color: AppColors.gold500,
            onTap: () => onChanged(_DeskTab.departures),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colors.bgSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: selected ? color : colors.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.textPrimary : colors.textTertiary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.15)
                      : colors.bgSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? color : colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Booking card ───────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final _DeskTab tab;
  final VoidCallback onConfirm;
  final VoidCallback onCall;

  const _BookingCard({
    required this.booking,
    required this.tab,
    required this.onConfirm,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = AppHelpers.bookingStatusColor(booking.status.value);
    final name = booking.customerName?.trim().isNotEmpty == true
        ? booking.customerName!.trim()
        : 'Khách lẻ';
    final initials = name.substring(0, 1).toUpperCase();
    final isHold = booking.status == BookingStatus.hold;
    final accent =
        tab == _DeskTab.arrivals ? colors.success : AppColors.gold500;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      booking.propertyName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stay timeline: check-in → check-out, with the relevant end accented.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _DateEnd(
                  caption: 'NHẬN',
                  date: booking.checkinDate,
                  highlight: tab == _DeskTab.arrivals,
                  color: colors.success,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.arrow_right_alt_rounded,
                          size: 20, color: colors.textTertiary),
                      Text(
                        '${booking.nights} đêm',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                _DateEnd(
                  caption: 'TRẢ',
                  date: booking.checkoutDate,
                  highlight: tab == _DeskTab.departures,
                  color: AppColors.gold500,
                  alignEnd: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Meta chips.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                icon: Icons.group_outlined,
                label: '${booking.guestCount} khách',
              ),
              if (booking.depositAmount != null && booking.depositAmount! > 0)
                _Chip(
                  icon: Icons.payments_outlined,
                  label:
                      'Cọc ${AppHelpers.formatPrice(booking.depositAmount!)}',
                ),
              if (booking.notes != null && booking.notes!.trim().isNotEmpty)
                _Chip(
                  icon: Icons.sticky_note_2_outlined,
                  label: booking.notes!.trim(),
                  flexible: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Actions.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded, size: 17),
                  label: const Text('Gọi khách'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderStrong),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              if (isHold && tab == _DeskTab.arrivals) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Xác nhận'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DateEnd extends StatelessWidget {
  final String caption;
  final DateTime date;
  final bool highlight;
  final Color color;
  final bool alignEnd;

  const _DateEnd({
    required this.caption,
    required this.date,
    required this.highlight,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: highlight ? color : colors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: highlight ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool flexible;
  const _Chip({required this.icon, required this.label, this.flexible = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textTertiary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
    return flexible
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200), child: box)
        : box;
  }
}
