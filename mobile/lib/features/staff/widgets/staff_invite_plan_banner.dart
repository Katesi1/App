import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/staff_entitlement.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_toast.dart';

/// Banner khóa / hướng dẫn nâng cấp khi gói không cho mời nhân viên.
class StaffInvitePlanBanner extends StatelessWidget {
  final UserModel user;

  const StaffInvitePlanBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canInvite = user.canInviteStaff;
    final reason = user.staffInviteBlockReason;
    if (canInvite || reason.isEmpty) return const SizedBox.shrink();

    final showUpgrade =
        user.hasStaffInviteSubscription && (user.maxStaffInviteSlots ?? 0) == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: colors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mời nhân viên bị khóa',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showUpgrade) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gói ${StaffEntitlement.minPlanLabel} trở lên: mời nhân viên qua '
              'email + mã HL-XXXXXX.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: showUpgrade || !user.hasStaffInviteSubscription
                  ? () => AppToast.show(
                        context,
                        message:
                            'Để mời nhân viên, bạn cần tối thiểu gói '
                            '${StaffEntitlement.minPlanLabel}.',
                        type: AppToastType.info,
                        actionLabel: 'Nâng cấp ngay →',
                        onAction: () =>
                            context.push(user.subscriptionPlanPickerRoute),
                      )
                  : () => context.push(user.subscriptionPlanPickerRoute),
              child: Text(
                showUpgrade || !user.hasStaffInviteSubscription
                    ? 'Xem gói nâng cấp'
                    : 'Quản lý gói',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.brand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
