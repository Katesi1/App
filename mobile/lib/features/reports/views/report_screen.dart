import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../data/models/booking_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/report_controller.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  Widget _header(BuildContext context, WidgetRef ref, DateTime now) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? user?.phone ?? '';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.oceanDeep, AppColors.ocean],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -50,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Báo cáo',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Thống kê tháng ${now.month}/${now.year}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.teal, AppColors.gold]),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final reportAsync = ref.watch(reportDataProvider(null));

    return AppScaffold(
      title: '',
      selectedIndex: 3,
      showAppBar: false,
      body: Column(
        children: [
          _header(context, ref, now),
          Expanded(
            child: reportAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(reportDataProvider(null)),
              ),
              data: (report) {
                final totalRooms = report.totalRooms;
                final activeRooms = report.activeRooms;
                final holdCount = report.holdCount;
                final confirmedCount = report.confirmedCount;
                final cancelledCount = report.cancelledCount;
                final completedCount = report.completedCount;
                final totalBookings = report.totalBookings;
                final totalDeposit = report.totalDeposit;
                final thisMonthCount = report.thisMonthBookings;
                final occupancyRate = report.occupancyRate;

                return RefreshIndicator(
                  color: AppColors.ocean,
                  onRefresh: () async {
                    ref.invalidate(reportDataProvider(null));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── KPI Cards (2x2) ────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.apartment_rounded,
                              iconBg: AppColors.oceanLight,
                              iconColor: AppColors.ocean,
                              label: 'Tổng phòng',
                              value: '$totalRooms',
                              sub: '$activeRooms đang hoạt động',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.percent_rounded,
                              iconBg: AppColors.emeraldLight,
                              iconColor: AppColors.emerald,
                              label: 'Tỷ lệ lấp đầy',
                              value: '${occupancyRate.toStringAsFixed(0)}%',
                              sub: 'Phòng có booking',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.book_rounded,
                              iconBg: AppColors.tealLight,
                              iconColor: AppColors.teal,
                              label: 'Tổng booking',
                              value: '$totalBookings',
                              sub: '$thisMonthCount tháng này',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.payments_rounded,
                              iconBg: AppColors.goldLight,
                              iconColor: AppColors.gold,
                              label: 'Tiền cọc thu',
                              value: AppHelpers.formatPrice(totalDeposit),
                              sub: 'Đã xác nhận + hoàn thành',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Booking Status Breakdown ───────
                      _SectionTitle(title: 'TRẠNG THÁI BOOKING'),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _StatusRow(
                              label: 'Đang giữ',
                              count: holdCount,
                              total: totalBookings,
                              color: AppColors.hold,
                            ),
                            const SizedBox(height: 12),
                            _StatusRow(
                              label: 'Đã xác nhận',
                              count: confirmedCount,
                              total: totalBookings,
                              color: AppColors.confirmed,
                            ),
                            const SizedBox(height: 12),
                            _StatusRow(
                              label: 'Hoàn thành',
                              count: completedCount,
                              total: totalBookings,
                              color: AppColors.completed,
                            ),
                            const SizedBox(height: 12),
                            _StatusRow(
                              label: 'Đã huỷ',
                              count: cancelledCount,
                              total: totalBookings,
                              color: AppColors.cancelled,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Phòng theo homestay ────────────
                      _SectionTitle(title: 'THÔNG TIN PHÒNG'),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Tổng số phòng',
                              value: '$totalRooms',
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            _InfoRow(
                              label: 'Phòng hoạt động',
                              value: '$activeRooms',
                              valueColor: AppColors.emerald,
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            _InfoRow(
                              label: 'Phòng tạm ngưng',
                              value: '${totalRooms - activeRooms}',
                              valueColor: AppColors.slate,
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            _InfoRow(
                              label: 'Có ảnh bìa',
                              value: '${report.roomsWithCover}',
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            _InfoRow(
                              label: 'Đã cập nhật giá',
                              value: '${report.roomsWithPrice}',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Booking gần đây ────────────────
                      _SectionTitle(title: 'BOOKING GẦN ĐÂY'),
                      const SizedBox(height: 12),

                      if (report.recentBookings.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.book_outlined,
                          message: 'Chưa có booking nào',
                        )
                      else
                        ...report.recentBookings.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RecentBookingCard(booking: b),
                          ),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Status Row with progress bar ─────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${(ratio * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.slateLight,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.navy,
          ),
        ),
      ],
    );
  }
}

// ─── Recent Booking Card ──────────────────────────────────────────────────────
class _RecentBookingCard extends StatelessWidget {
  final BookingModel booking;
  const _RecentBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusLabel = booking.status.label;
    final statusColor =
        AppHelpers.bookingStatusColor(booking.status.value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.oceanLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.book_outlined,
              color: AppColors.ocean,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? 'Không tên',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.propertyName} · ${booking.nights} đêm',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

