import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/staff_entitlement.dart';
import '../../data/models/user_model.dart';

/// Full-screen upsell shown when an OWNER can't add/invite staff — explains the
/// reason and points to the exact next action (verify / buy / upgrade / renew).
///
/// Shared between the OWNER staff list ([/admin/users]) and the invite screen
/// ([/staff/manage]) so both surfaces show the same "Starter+ to add staff"
/// message and CTA.
class StaffUpsellView extends StatelessWidget {
  final InviteEligibility eligibility;
  final UserModel? user;

  const StaffUpsellView({
    super.key,
    required this.eligibility,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spec = _UpsellSpec.of(eligibility.blockReason!, user);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  spec.accent.withValues(alpha: 0.18),
                  spec.accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(spec.icon, size: 34, color: spec.accent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            spec.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            eligibility.reason ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Plans that unlock staff — when buying/upgrading (or KYC) is involved.
          if (eligibility.showsPlanOptions) ...[
            const _PlanPerksCard(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Primary CTA.
          if (spec.route != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(spec.route!),
                style: FilledButton.styleFrom(
                  backgroundColor: spec.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(spec.ctaIcon, size: 18),
                label: Text(
                  spec.ctaLabel,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One row in the [_PlanPerksCard] — a plan group + its staff allowance.
class _PlanPerkRow extends StatelessWidget {
  final String plans;
  final String slots;
  final bool highlight;

  const _PlanPerkRow({
    required this.plans,
    required this.slots,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            highlight
                ? Icons.workspace_premium_rounded
                : Icons.check_circle_rounded,
            size: 18,
            color: highlight ? colors.brandSecondary : colors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              plans,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            slots,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? colors.brandSecondary : colors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card listing which plans unlock staff invites (and how many).
class _PlanPerksCard extends StatelessWidget {
  const _PlanPerksCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GÓI MỞ KHOÁ THÊM NHÂN VIÊN',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _PlanPerkRow(plans: 'Starter · Standard', slots: '3 nhân viên'),
          Divider(height: 1, color: colors.borderSubtle),
          const _PlanPerkRow(
            plans: 'Pro · Business · Enterprise',
            slots: 'Không giới hạn',
            highlight: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.block_rounded, size: 16, color: colors.textTertiary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Gói Mini — không hỗ trợ nhân viên',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Per-reason copy + styling + navigation target for [StaffUpsellView].
class _UpsellSpec {
  final IconData icon;
  final String title;
  final Color accent;
  final String ctaLabel;
  final IconData ctaIcon;
  final String? route;

  const _UpsellSpec({
    required this.icon,
    required this.title,
    required this.accent,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.route,
  });

  factory _UpsellSpec.of(InviteBlockReason reason, UserModel? user) {
    switch (reason) {
      case InviteBlockReason.kycRequired:
        final pending = user?.isKycPending ?? false;
        return _UpsellSpec(
          icon: Icons.verified_user_outlined,
          title: 'Xác minh để thêm nhân viên',
          accent: AppColors.ocean,
          ctaLabel: pending ? 'Xem trạng thái duyệt' : 'Xác minh ngay',
          ctaIcon: pending ? Icons.hourglass_top_rounded : Icons.badge_rounded,
          route: pending ? '/verify/pending' : '/verify/cccd-front',
        );
      case InviteBlockReason.subscriptionInactive:
        return const _UpsellSpec(
          icon: Icons.workspace_premium_outlined,
          title: 'Mua gói để thêm nhân viên',
          accent: AppColors.ocean,
          ctaLabel: 'Xem các gói',
          ctaIcon: Icons.arrow_forward_rounded,
          route: '/verify/select-plan',
        );
      case InviteBlockReason.subscriptionPastDue:
        return const _UpsellSpec(
          icon: Icons.event_repeat_rounded,
          title: 'Gia hạn để tiếp tục',
          accent: AppColors.amber,
          ctaLabel: 'Gia hạn ngay',
          ctaIcon: Icons.autorenew_rounded,
          route: '/verify/subscription-detail',
        );
      case InviteBlockReason.subscriptionFrozen:
        return const _UpsellSpec(
          icon: Icons.ac_unit_rounded,
          title: 'Tài khoản đang tạm khoá',
          accent: AppColors.coral,
          ctaLabel: 'Liên hệ hỗ trợ',
          ctaIcon: Icons.support_agent_rounded,
          route: '/profile/help',
        );
      case InviteBlockReason.planNotAllowed:
        return const _UpsellSpec(
          icon: Icons.upgrade_rounded,
          title: 'Nâng cấp để thêm nhân viên',
          accent: AppColors.gold,
          ctaLabel: 'Nâng cấp gói',
          ctaIcon: Icons.upgrade_rounded,
          route: '/verify/select-plan',
        );
      case InviteBlockReason.slotLimitReached:
        return const _UpsellSpec(
          icon: Icons.groups_rounded,
          title: 'Đã đạt giới hạn nhân viên',
          accent: AppColors.gold,
          ctaLabel: 'Nâng cấp gói',
          ctaIcon: Icons.upgrade_rounded,
          route: '/verify/select-plan',
        );
      case InviteBlockReason.notOwner:
        return const _UpsellSpec(
          icon: Icons.lock_outline_rounded,
          title: 'Không có quyền thêm nhân viên',
          accent: AppColors.slate,
          ctaLabel: '',
          ctaIcon: Icons.lock_outline_rounded,
          route: null,
        );
    }
  }
}
