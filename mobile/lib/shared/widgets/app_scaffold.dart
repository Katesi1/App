import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool showBottomNav;
  final int? selectedIndex;
  final Widget? bottomSheet;
  final bool resizeToAvoidBottomInset;
  final bool showAppBar;
  final PreferredSizeWidget? customAppBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.showBottomNav = true,
    this.selectedIndex,
    this.bottomSheet,
    this.resizeToAvoidBottomInset = true,
    this.showAppBar = true,
    this.customAppBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: customAppBar ??
          (showAppBar
              ? AppBar(
                  title: Text(title),
                  actions: [
                    ...?actions,

                    // Theme toggle
                    IconButton(
                      tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            RotationTransition(
                          turns: anim,
                          child:
                              FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey(isDark),
                          color: colors.primary,
                        ),
                      ),
                      onPressed: () =>
                          ref.read(themeProvider.notifier).toggle(),
                    ),

                    // User avatar + menu
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: PopupMenuButton<String>(
                        tooltip: 'Tài khoản',
                        offset: const Offset(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.md),
                        ),
                        icon: CircleAvatar(
                          backgroundColor: colors.primary,
                          radius: 18,
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.nunito(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        itemBuilder: (_) => [
                          // User info header
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? '',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _roleColor(user?.role)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.full),
                                  ),
                                  child: Text(
                                    _roleLabel(user?.role),
                                    style: GoogleFonts.nunito(
                                      color: _roleColor(user?.role),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          // Logout
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Đăng xuất',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : null),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          showBottomNav ? _BottomNav(selectedIndex: selectedIndex ?? 0) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomSheet: bottomSheet,
    );
  }

  String _roleLabel(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'OWNER':
        return 'Chủ nhà';
      case 'SALE':
        return 'Sale';
      default:
        return role ?? '';
    }
  }

  Color _roleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return AppColors.error;
      case 'OWNER':
        return AppColors.completed;
      case 'SALE':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _BottomNav extends ConsumerStatefulWidget {
  final int selectedIndex;
  const _BottomNav({required this.selectedIndex});

  @override
  ConsumerState<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends ConsumerState<_BottomNav>
    with SingleTickerProviderStateMixin {
  late int _current;

  // Tab items (excluding center + button)
  static const _navItems = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
      route: '/rooms',
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Lịch',
      route: '/bookings',
    ),
    // Index 2 is the center + button (placeholder, not rendered here)
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Liên hệ',
      route: '/homestays',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Cá nhân',
      route: '/admin/users',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _current = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(_BottomNav old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      setState(() => _current = widget.selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left tabs (Home, Calendar)
              _buildNavItem(0, _navItems[0], colors),
              _buildNavItem(1, _navItems[1], colors),

              // Center FAB (+ button)
              _buildCenterFab(context, colors, isDark),

              // Right tabs (Contact, Profile)
              _buildNavItem(2, _navItems[2], colors),
              _buildNavItem(3, _navItems[3], colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, ColorScheme colors) {
    final isSelected = _current == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _current = index);
          context.go(item.route);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? colors.primary : colors.outline,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.outline,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab(
    BuildContext context,
    ColorScheme colors,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _showAddOptions(context, colors),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight,
                AppColors.primary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
          delay: 200.ms,
        );
  }

  void _showAddOptions(BuildContext context, ColorScheme colors) {
    final user = ref.read(currentUserProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tạo mới',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (user?.canEdit == true)
              _AddOptionTile(
                icon: Icons.bed_rounded,
                iconColor: AppColors.primary,
                title: 'Thêm phòng',
                subtitle: 'Tạo phòng mới cho homestay',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/rooms/new');
                },
              ),
            if (user?.canEdit == true)
              _AddOptionTile(
                icon: Icons.home_work_rounded,
                iconColor: AppColors.info,
                title: 'Thêm homestay',
                subtitle: 'Tạo homestay mới',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/homestays/new');
                },
              ),
            _AddOptionTile(
              icon: Icons.event_available_rounded,
              iconColor: AppColors.secondary,
              title: 'Đặt phòng',
              subtitle: 'Tạo booking mới',
              onTap: () {
                Navigator.pop(ctx);
                context.go('/bookings');
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: colors.outline,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: colors.outline,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
