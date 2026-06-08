import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/subscription_gating.dart';
import '../../data/models/user_model.dart';

/// Banner subscription/frozen cho OWNER trên dashboard và các màn quản lý.
class SubscriptionStatusBanner extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onRenewTap;

  const SubscriptionStatusBanner({
    super.key,
    required this.user,
    this.onRenewTap,
  });

  @override
  Widget build(BuildContext context) {
    if (user.isSubscriptionFrozen) {
      return _FrozenBanner(user: user);
    }
    return const SizedBox.shrink();
  }
}

class _FrozenBanner extends StatelessWidget {
  final UserModel user;
  const _FrozenBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_person_outlined,
              color: AppColors.coral, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tài khoản tạm khoá',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SubscriptionGating.frozenBannerMessage(user),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AppColors.brownDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/profile/help'),
            child: const Text('Hỗ trợ'),
          ),
        ],
      ),
    );
  }
}

/// Chip hiển thị quota nhân viên đang dùng (vd 2/3).
class StaffSlotUsageChip extends StatelessWidget {
  final int used;
  final int? max;

  const StaffSlotUsageChip({super.key, required this.used, required this.max});

  @override
  Widget build(BuildContext context) {
    if (max == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.oceanPale,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        'Đã dùng $used/$max slot nhân viên',
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.oceanDeep,
        ),
      ),
    );
  }
}
