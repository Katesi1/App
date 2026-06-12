import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/staff_entitlement.dart';
import '../../../core/utils/subscription_gating.dart';
import '../../../data/models/user_model.dart';

/// Banner khóa / hướng dẫn nâng cấp khi gói không cho mời nhân viên.
class StaffInvitePlanBanner extends StatelessWidget {
  final UserModel user;

  const StaffInvitePlanBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final block = SubscriptionGating.staffInviteBlock(user);
    final reason = user.staffInviteBlockReason;
    if (block == StaffInviteBlock.none || reason.isEmpty) {
      return const SizedBox.shrink();
    }

    // Chỉ gợi ý mua/nâng gói khi lý do thật sự là gói (chưa có gói / Mini).
    // KYC → CTA xác minh; đã có gói (trial/active) → KHÔNG hiện nút gói.
    final isPlanBlock = block == StaffInviteBlock.plan;
    final isKycBlock = block == StaffInviteBlock.kyc;

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
          if (isPlanBlock) ...[
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
          // Đã có gói (trial/active) bị chặn vì KYC → CTA xác minh, KHÔNG hiện
          // nút mua/quản lý gói. Chỉ block do gói mới hiện nút nâng gói.
          if (isPlanBlock || isKycBlock) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isKycBlock
                    ? () => context.push('/verify/cccd-front')
                    : () => context.push(user.subscriptionPlanPickerRoute),
                child: Text(
                  isKycBlock ? 'Xác minh ngay' : 'Xem gói nâng cấp',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.brand,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
