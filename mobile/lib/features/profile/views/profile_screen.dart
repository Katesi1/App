import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/user_model.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../verify/data/models/plan.dart';
import '../../verify/data/models/verify_enums.dart';
import '../../verify/views/paywall_modal.dart';

// gradient.brandHero stop "jade-mid" per spec section 3.7 — no token available yet
const _jadeMidLight = Color(0xFF1B7E94);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final showVerifySection = user?.isOwner ?? false;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(user: user, topPad: topPad, isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.04, end: 0),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('TÀI KHOẢN'),
                  const SizedBox(height: 8),
                  _MenuCard(
                    isDark: isDark,
                    items: [
                      _MenuItemData(
                        icon: Icons.person_outline_rounded,
                        label: 'Thông tin cá nhân',
                        subtitle: 'Cập nhật hồ sơ của bạn',
                        iconColor: colors.brand,
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _MenuItemData(
                        icon: Icons.lock_outline_rounded,
                        label: 'Đổi mật khẩu',
                        subtitle: 'Bảo mật tài khoản',
                        iconColor: colors.brand,
                        onTap: () => context.push('/profile/change-password'),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // KYC + Subscription section (Owner only)
            if (showVerifySection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(AppConfig.hidePaidUpgradeUI
                        ? 'XÁC THỰC DANH TÍNH'
                        : 'XÁC THỰC + GÓI ĐĂNG KÝ'),
                    const SizedBox(height: 8),
                    _MenuCard(
                      isDark: isDark,
                      items: [
                        _kycMenuItem(context, user!.kycStatus, colors),
                        // iOS (Guideline 3.1.1): no paid-upgrade entry point.
                        if (AppConfig.showPaidUpgradeUI)
                          _subscriptionMenuItem(context, user, colors),
                      ],
                    ),
                  ],
                ),
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0),

            if (showVerifySection) const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('CÀI ĐẶT'),
                  const SizedBox(height: 8),
                  _MenuCard(
                    isDark: isDark,
                    items: [
                      _MenuItemData(
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        label: 'Chế độ tối',
                        subtitle: isDark ? 'Đang bật' : 'Đang tắt',
                        iconColor: colors.textPrimary,
                        isToggle: true,
                        toggleValue: isDark,
                        onToggle: (_) =>
                            ref.read(themeProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('HỖ TRỢ'),
                  const SizedBox(height: 8),
                  _MenuCard(
                    isDark: isDark,
                    items: [
                      _MenuItemData(
                        icon: Icons.help_outline_rounded,
                        label: 'Trợ giúp',
                        subtitle: 'Câu hỏi thường gặp & liên hệ',
                        iconColor: colors.warning,
                        onTap: () => context.push('/profile/help'),
                      ),
                      _MenuItemData(
                        icon: Icons.notifications_active_outlined,
                        label: 'Tùy chọn thông báo',
                        subtitle: 'Booking, thanh toán, hệ thống',
                        iconColor: colors.brand,
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      _MenuItemData(
                        icon: Icons.feedback_outlined,
                        label: 'Gửi phản hồi / Báo lỗi',
                        subtitle: 'Tạo ticket hỗ trợ',
                        iconColor: colors.success,
                        onTap: () => context.push('/profile/feedback'),
                      ),
                      _MenuItemData(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Yêu cầu hỗ trợ của tôi',
                        subtitle: 'Theo dõi tiến độ xử lý',
                        iconColor: colors.brandSecondary,
                        onTap: () => context.push('/profile/tickets'),
                      ),
                      _MenuItemData(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Quyền riêng tư',
                        subtitle: 'Chính sách bảo vệ dữ liệu',
                        iconColor: colors.textSecondary,
                        onTap: () => context.push('/profile/privacy'),
                      ),
                      _MenuItemData(
                        icon: Icons.fact_check_outlined,
                        label: 'Quyền đồng ý dữ liệu',
                        subtitle: 'Quản lý consent KYC & marketing',
                        iconColor: colors.brand,
                        onTap: () => context.push('/profile/consent'),
                      ),
                      _MenuItemData(
                        icon: Icons.download_outlined,
                        label: 'Yêu cầu dữ liệu cá nhân',
                        subtitle: 'Xuất bản sao dữ liệu (GDPR)',
                        iconColor: colors.brandSecondary,
                        onTap: () => context.push('/profile/data-request'),
                      ),
                      _MenuItemData(
                        icon: Icons.gavel_outlined,
                        label: 'Điều khoản sử dụng',
                        subtitle: 'Điều khoản dịch vụ',
                        iconColor: colors.textSecondary,
                        onTap: () => context.push('/profile/terms'),
                      ),
                      _MenuItemData(
                        icon: Icons.delete_forever_outlined,
                        label: 'Xoá tài khoản',
                        subtitle: 'Xoá vĩnh viễn dữ liệu của bạn',
                        iconColor: colors.error,
                        onTap: () => context.push('/profile/delete-account'),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                icon: Icon(
                  Icons.logout_rounded,
                  color: colors.error,
                  size: 20,
                ),
                label: Text(
                  'Đăng xuất',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(
                    color: colors.error,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            Center(
              child: Text(
                'Halong24h v1.0.0',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
            ).animate(delay: 450.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogColors = ctx.colors;
        return AlertDialog(
          title: Text(
            'Đăng xuất?',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất?',
            style: GoogleFonts.beVietnamPro(color: dialogColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Huỷ',
                style:
                    GoogleFonts.beVietnamPro(color: dialogColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Đăng xuất',
                style: GoogleFonts.beVietnamPro(
                  color: dialogColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  /// KYC menu item — driven by the SERVER truth (`user.kycStatus`), not the
  /// local verify-flow draft (which could be stale and wrongly invite the user
  /// to "verify again" while the backend already has the submission pending).
  ///
  /// - `pending`: "Hồ sơ đang chờ duyệt" → tap opens the contact sheet
  ///   (call / email admin) instead of re-entering the KYC flow.
  /// - `approved`: "Đã xác thực danh tính" (info only).
  /// - `rejected`: "Cần bổ sung hồ sơ" → /verify/rejected.
  /// - `none`/other: "Xác thực CCCD" → paywall → /verify/cccd-front.
  _MenuItemData _kycMenuItem(
    BuildContext context,
    String kycStatus,
    AppColorScheme colors,
  ) {
    switch (kycStatus) {
      case 'pending':
        return _MenuItemData(
          icon: Icons.access_time_rounded,
          label: 'Hồ sơ đang chờ duyệt',
          subtitle: 'Admin phản hồi trong 24h · Chạm để liên hệ',
          iconColor: colors.brandSecondary,
          onTap: () => _showKycContactSheet(context),
        );
      case 'approved':
        return _MenuItemData(
          icon: Icons.verified_user_rounded,
          label: 'Đã xác thực danh tính',
          subtitle: 'CCCD đã được duyệt',
          iconColor: colors.success,
          // Info only — no action.
        );
      case 'rejected':
        return _MenuItemData(
          icon: Icons.error_outline_rounded,
          label: 'Cần bổ sung hồ sơ',
          subtitle: 'Admin yêu cầu chụp lại — chạm để gửi lại',
          iconColor: colors.error,
          onTap: () => context.push('/verify/rejected'),
        );
      default:
        // iOS (Guideline 3.1.1): KYC stays available for identity, but with no
        // trial/plan/payment language and no paywall — straight to capture.
        if (AppConfig.hidePaidUpgradeUI) {
          return _MenuItemData(
            icon: Icons.verified_user_outlined,
            label: 'Xác thực danh tính',
            subtitle: 'Xác minh CCCD chủ nhà',
            iconColor: AppColors.goldText,
            onTap: () => context.push('/verify/cccd-front'),
          );
        }
        return _MenuItemData(
          icon: Icons.verified_user_outlined,
          label: 'Xác thực CCCD để đăng phòng',
          subtitle: '3 bước · Trial 7 ngày miễn phí',
          iconColor: AppColors.goldText,
          onTap: () async {
            final route = await showPaywallModal(context);
            if (route != null && context.mounted) {
              context.push(route);
            }
          },
        );
    }
  }

  /// Subscription menu item — always shown for owners, separate from KYC.
  /// Routes to the manage screen when there's a live paid plan, otherwise to
  /// the plan picker.
  _MenuItemData _subscriptionMenuItem(
    BuildContext context,
    UserModel user,
    AppColorScheme colors,
  ) {
    final hasPaidPlan = user.isSubscriptionActive || user.isSubscriptionPastDue;
    final planName = Plan.tierFromId(user.subscriptionPlanId)?.displayName;
    final String subtitle;
    if (hasPaidPlan) {
      subtitle = 'Gói ${planName ?? '—'} · Nâng cấp, gia hạn, lịch sử';
    } else if (user.isInTrial) {
      subtitle = 'Đang dùng thử · Chọn gói để duy trì sau trial';
    } else {
      subtitle = 'Chưa có gói · Chọn gói phù hợp số phòng';
    }
    return _MenuItemData(
      icon: Icons.workspace_premium_rounded,
      label: 'Gói đăng ký',
      subtitle: subtitle,
      iconColor: colors.warning,
      onTap: () => context.push(
        hasPaidPlan ? '/verify/subscription-detail' : '/verify/select-plan',
      ),
    );
  }

  /// Bottom sheet shown when the user taps a pending-KYC item — lets them
  /// reach the admin team by phone or email while the review is in progress.
  void _showKycContactSheet(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bgSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Liên hệ hỗ trợ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hồ sơ đang chờ admin duyệt. Cần hỗ trợ nhanh, hãy liên hệ:',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phone_outlined, color: colors.brand),
                title: const Text('Gọi hỗ trợ'),
                subtitle: const Text(AppConstants.supportPhone),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final uri =
                      Uri(scheme: 'tel', path: AppConstants.supportPhone);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.mail_outline, color: colors.brandSecondary),
                title: const Text('Gửi email'),
                subtitle: const Text(AppConstants.supportEmail),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final uri =
                      Uri(scheme: 'mailto', path: AppConstants.supportEmail);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile Header ─────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final double topPad;
  final bool isDark;

  const _ProfileHeader({
    required this.user,
    required this.topPad,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        (user?.name?.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';

    final headerGradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 16,
        left: 24,
        right: 24,
        bottom: 32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.4, -1),
          end: const Alignment(0.6, 1),
          colors: headerGradient,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Back button row
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Avatar with gradient ring + pulsing shimmer
          _GradientAvatar(initial: initial),

          const SizedBox(height: 16),

          // Name
          Text(
            user?.name ?? '',
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              AppHelpers.roleLabel(user?.role),
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Phone
          if (user?.phone != null && user!.phone.isNotEmpty)
            Text(
              user!.phone,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),

          // Email
          if (user?.email != null && user!.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user!.email!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Gradient Avatar with pulsing ring ──────────────────────────────────────

class _GradientAvatar extends StatefulWidget {
  final String initial;
  const _GradientAvatar({required this.initial});

  @override
  State<_GradientAvatar> createState() => _GradientAvatarState();
}

class _GradientAvatarState extends State<_GradientAvatar>
    with WidgetsBindingObserver {
  bool _tickersEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause shimmer while the app is in the background so the ticker doesn't
    // churn forever when the device is locked or the user switches apps.
    final enabled = state == AppLifecycleState.resumed;
    if (enabled != _tickersEnabled && mounted) {
      setState(() => _tickersEnabled = enabled);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TickerMode(
      enabled: _tickersEnabled,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing outer ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors.brand, AppColors.gold500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 2000.ms,
                color: Colors.white.withValues(alpha: 0.4),
                angle: 0.5,
              )
              .then()
              .shimmer(
                duration: 2000.ms,
                delay: 500.ms,
                color: Colors.white.withValues(alpha: 0.2),
              ),

          // White spacing ring
          Container(
            width: 94,
            height: 94,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          // Avatar inner circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.jade500, _jadeMidLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.initial,
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Menu Item Data ──────────────────────────────────────────────────────────

class _MenuItemData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool toggleValue;
  final ValueChanged<bool>? onToggle;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
    this.isToggle = false,
    this.toggleValue = false,
    this.onToggle,
  });
}

// ─── Menu Card ───────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final bool isDark;
  final List<_MenuItemData> items;

  const _MenuCard({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 72,
                color: colors.borderDefault,
              ),
            items[i].isToggle
                ? _ToggleRow(item: items[i], isDark: isDark)
                : _TapRow(item: items[i], isDark: isDark),
          ],
        ],
      ),
    );
  }
}

// ─── Tap Row ─────────────────────────────────────────────────────────────────

class _TapRow extends StatelessWidget {
  final _MenuItemData item;
  final bool isDark;

  const _TapRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Icon container 44px
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
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
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final _MenuItemData item;
  final bool isDark;

  const _ToggleRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => item.onToggle?.call(!item.toggleValue),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            children: [
              // Icon container 44px
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: item.toggleValue,
                activeThumbColor: colors.brand,
                onChanged: item.onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
