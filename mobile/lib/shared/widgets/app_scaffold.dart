import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../providers/theme_provider.dart';
import '../providers/view_mode_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/helpers.dart';

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
                    IconButton(
                      tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            RotationTransition(
                          turns: anim,
                          child: FadeTransition(
                              opacity: anim, child: child),
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
                    Padding(
                      padding:
                          const EdgeInsets.only(right: AppSpacing.sm),
                      child: PopupMenuButton<String>(
                        tooltip: 'Tài khoản',
                        offset: const Offset(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.md),
                        ),
                        icon: CircleAvatar(
                          backgroundColor: AppColors.ocean,
                          radius: 18,
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        itemBuilder: (_) {
                          final isCustomerMode =
                              ref.read(isCustomerModeProvider);
                          final canToggle =
                              user?.isManagement == true;

                          return [
                            PopupMenuItem<String>(
                              enabled: false,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? '',
                                    style: GoogleFonts.beVietnamPro(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppHelpers.roleColor(
                                              user?.role)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppRadius.full),
                                    ),
                                    child: Text(
                                      AppHelpers.roleLabel(
                                          user?.role),
                                      style:
                                          GoogleFonts.beVietnamPro(
                                        color:
                                            AppHelpers.roleColor(
                                                user?.role),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ── Toggle chế độ xem (chỉ ADMIN/STAFF) ──
                            if (canToggle) ...[
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'toggle_mode',
                                child: Row(
                                  children: [
                                    Icon(
                                      isCustomerMode
                                          ? Icons
                                              .admin_panel_settings_outlined
                                          : Icons
                                              .person_outline_rounded,
                                      color: AppColors.ocean,
                                      size: 20,
                                    ),
                                    const SizedBox(
                                        width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        isCustomerMode
                                            ? 'Chế độ quản lý'
                                            : 'Xem như khách',
                                        style:
                                            GoogleFonts.beVietnamPro(
                                          color: AppColors.ocean,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCustomerMode
                                            ? AppColors.teal
                                                .withValues(
                                                    alpha: 0.1)
                                            : AppColors.ocean
                                                .withValues(
                                                    alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppRadius.full),
                                      ),
                                      child: Text(
                                        isCustomerMode
                                            ? 'Khách'
                                            : 'Quản lý',
                                        style:
                                            GoogleFonts.beVietnamPro(
                                          fontSize: 9,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: isCustomerMode
                                              ? AppColors.teal
                                              : AppColors.ocean,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  ref
                                      .read(viewModeProvider
                                          .notifier)
                                      .toggle();
                                  // Navigate sau khi popup đóng
                                  Future.microtask(() {
                                    if (context.mounted) {
                                      context.go(isCustomerMode
                                          ? '/dashboard'
                                          : '/home');
                                    }
                                  });
                                },
                              ),
                            ],
                            const PopupMenuDivider(),
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  const Icon(Icons.logout_rounded,
                                      color: AppColors.coral,
                                      size: 20),
                                  const SizedBox(
                                      width: AppSpacing.sm),
                                  Text(
                                    'Đăng xuất',
                                    style:
                                        GoogleFonts.beVietnamPro(
                                      color: AppColors.coral,
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
                          ];
                        },
                      ),
                    ),
                  ],
                )
              : null),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? _BottomNav(selectedIndex: selectedIndex ?? 0)
          : null,
      bottomSheet: bottomSheet,
    );
  }

}

// ─── Bottom Navigation — dynamic tabs based on user role ────────────────────

class _BottomNav extends ConsumerStatefulWidget {
  final int selectedIndex;
  const _BottomNav({required this.selectedIndex});

  @override
  ConsumerState<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends ConsumerState<_BottomNav> {
  late int _current;

  // ── Nav items theo role ────────────────────────────────────────────
  static const _staffNavItems = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Tổng quan',
      route: '/dashboard',
    ),
    _NavItem(
      icon: Icons.apartment_outlined,
      activeIcon: Icons.apartment_rounded,
      label: 'Phòng',
      route: '/rooms',
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Lịch',
      route: '/calendar',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Báo cáo',
      route: '/homestays',
    ),
  ];

  static const _adminExtraItem = _NavItem(
    icon: Icons.admin_panel_settings_outlined,
    activeIcon: Icons.admin_panel_settings_rounded,
    label: 'Quản lý',
    route: '/admin/users',
  );

  static const _customerNavItems = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
      route: '/home',
    ),
    _NavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Tìm phòng',
      route: '/search',
    ),
    _NavItem(
      icon: Icons.book_outlined,
      activeIcon: Icons.book_rounded,
      label: 'Booking',
      route: '/my-bookings',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Tài khoản',
      route: '/account',
    ),
  ];

  List<_NavItem> _getNavItems(UserModel? user, bool isCustomerMode) {
    if (user == null) return _staffNavItems;

    // Chế độ khách (CUSTOMER thuần hoặc ADMIN/STAFF toggle)
    if (isCustomerMode) return _customerNavItems;

    // ADMIN: staff tabs + quản lý tab
    if (user.isAdmin) {
      return [..._staffNavItems, _adminExtraItem];
    }

    // STAFF: chỉ staff tabs
    return _staffNavItems;
  }

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
    final user = ref.watch(currentUserProvider);
    final isCustomerMode = ref.watch(isCustomerModeProvider);
    final navItems = _getNavItems(user, isCustomerMode);

    // Clamp index to valid range
    if (_current >= navItems.length) {
      _current = 0;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Row(
            children: List.generate(navItems.length, (i) {
              return _buildNavItem(i, navItems[i]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
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
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.ocean : AppColors.slate,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.ocean : AppColors.slate,
              ),
            ),
          ],
        ),
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
