import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/notifications/controllers/notification_controller.dart';

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
    // Chỉ cần tên để render avatar chữ đầu — dùng select() để tránh rebuild
    // toàn bộ AppScaffold khi field khác của user thay đổi (role, KYC...).
    final userName = ref.watch(
      currentUserProvider.select((u) => u?.name ?? ''),
    );
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: customAppBar ??
          (showAppBar
              ? AppBar(
                  title: Text(title),
                  actions: [
                    ...?actions,
                    _NotificationBell(),
                    IconButton(
                      tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey(isDark),
                          color: isDark ? AppColors.oceanBright : Colors.white,
                        ),
                      ),
                      onPressed: () =>
                          ref.read(themeProvider.notifier).toggle(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.teal, AppColors.gold],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : null),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          showBottomNav ? _BottomNav(selectedIndex: selectedIndex ?? 0) : null,
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
      route: '/reports',
    ),
  ];

  static const _adminExtraItem = _NavItem(
    icon: Icons.admin_panel_settings_outlined,
    activeIcon: Icons.admin_panel_settings_rounded,
    label: 'Quản lý',
    route: '/admin',
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

    // ADMIN + OWNER: staff tabs + quản lý tab
    if (user.isAdmin || user.isOwner) {
      return [..._staffNavItems, _adminExtraItem];
    }

    // SALE: chỉ staff tabs
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : AppColors.ink.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : AppColors.ocean.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(navItems.length, (i) {
                return _buildNavItem(i, navItems[i]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
    final isSelected = _current == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.oceanBright : AppColors.ocean;
    final inactiveColor = isDark ? AppColors.darkHint : AppColors.slate;

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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? isDark
                        ? AppColors.oceanBright.withValues(alpha: 0.15)
                        : AppColors.oceanLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final count = unreadAsync.valueOrNull ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: 'Thông báo',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: isDark ? AppColors.oceanBright : Colors.white,
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => context.push('/notifications'),
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
