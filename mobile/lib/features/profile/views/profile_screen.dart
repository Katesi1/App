import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/providers/theme_provider.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7 — chưa có token sẵn
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

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Immersive gradient header ──────────────────────────
            _ProfileHeader(user: user, topPad: topPad, isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.04, end: 0),

            const SizedBox(height: 24),

            // ── Section: TÀI KHOẢN ────────────────────────────────
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
                        onTap: () =>
                            context.push('/profile/change-password'),
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

            // ── Section: CÀI ĐẶT ──────────────────────────────────
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

            // ── Section: HỖ TRỢ ───────────────────────────────────
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
                    ],
                  ),
                ],
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            // ── Logout button ──────────────────────────────────────
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
                    borderRadius:
                        BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // ── App version ────────────────────────────────────────
            Center(
              child: Text(
                'Halong24h v1.0.0',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
            )
                .animate(delay: 450.ms)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref) async {
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
            style:
                GoogleFonts.beVietnamPro(color: dialogColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Huỷ',
                style: GoogleFonts.beVietnamPro(
                    color: dialogColors.textSecondary),
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
    final initial = (user?.name?.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : 'U';

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

class _GradientAvatar extends StatelessWidget {
  final String initial;
  const _GradientAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
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
            initial,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 34,
            ),
          ),
        ),
      ],
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
            color:
                Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
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
                  color:
                      item.iconColor.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
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
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
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
