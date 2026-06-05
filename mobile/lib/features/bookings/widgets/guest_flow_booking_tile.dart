import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/booking_model.dart';
import '../utils/guest_flow_filter.dart';

class GuestFlowBookingTile extends StatelessWidget {
  final BookingModel booking;
  final GuestFlowType flowType;
  final VoidCallback onTap;

  const GuestFlowBookingTile({
    super.key,
    required this.booking,
    required this.flowType,
    required this.onTap,
  });

  String _flowDateLabel() {
    final targetDate = flowType == GuestFlowType.checkIn
        ? booking.checkinDate
        : booking.checkoutDate;
    final today = GuestFlowFilter.dateOnly(DateTime.now());
    final target = GuestFlowFilter.dateOnly(targetDate);
    final fmt = DateFormat('dd/MM/yyyy');

    if (target == today) {
      return 'Hôm nay · ${fmt.format(target)}';
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (target == tomorrow) {
      return 'Ngày mai · ${fmt.format(target)}';
    }
    return fmt.format(target);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = AppHelpers.bookingStatusColor(booking.status.value);
    final flowIcon = flowType == GuestFlowType.checkIn
        ? Icons.login_rounded
        : Icons.logout_rounded;

    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(flowIcon, size: 20, color: colors.brand),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? 'Khách chưa có tên',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _flowDateLabel(),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textBrand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (booking.customerPhone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        booking.customerPhone!,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${booking.nights} đêm · ${booking.guestCount} khách',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  booking.status.label,
                  style: GoogleFonts.beVietnamPro(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
