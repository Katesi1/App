import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/view_mode_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppScaffold(
      title: 'Tài khoản',
      selectedIndex: 3,
      showAppBar: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile header ────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.4, -1),
                  end: Alignment(0.4, 1),
                  colors: [AppColors.oceanDeep, AppColors.ocean],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      AppHelpers.roleLabel(user?.role),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.phone ?? '',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  if (user?.email != null &&
                      user!.email!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email!,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── Menu items ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // ── Toggle quản lý (chỉ ADMIN/STAFF) ──────────
                  if (user?.isManagement == true) ...[
                    _MenuItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Chuyển sang quản lý',
                      color: AppColors.ocean,
                      onTap: () {
                        ref
                            .read(viewModeProvider.notifier)
                            .setMode(ViewMode.management);
                        context.go('/dashboard');
                      },
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ocean
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                              AppRadius.full),
                        ),
                        child: Text(
                          AppHelpers.roleLabel(user?.role),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ocean,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 4),
                  ],
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Thông tin cá nhân',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Đổi mật khẩu',
                    onTap: () =>
                        context.push('/profile/change-password'),
                  ),
                  _MenuItem(
                    icon: Icons.book_outlined,
                    label: 'Lịch sử đặt phòng',
                    onTap: () => context.go('/my-bookings'),
                  ),
                  _MenuItem(
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                    onTap: () =>
                        ref.read(themeProvider.notifier).toggle(),
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: AppColors.ocean,
                      onChanged: (_) =>
                          ref.read(themeProvider.notifier).toggle(),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Trợ giúp',
                    onTap: () =>
                        context.push('/profile/help'),
                  ),
                  const SizedBox(height: 8),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    color: AppColors.coral,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            'Đăng xuất?',
                            style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: Text(
                                'Huỷ',
                                style: GoogleFonts.beVietnamPro(
                                    color: AppColors.muted),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: Text(
                                'Đăng xuất',
                                style: GoogleFonts.beVietnamPro(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await ref
                            .read(authProvider.notifier)
                            .logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                  ),
                ],
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Item ──────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.navy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.slate, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
