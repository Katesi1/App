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
import 'bank_required_dialog.dart';

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

  /// Hiện bộ action mặc định (chuông thông báo, nút đổi theme, avatar). Tắt
  /// cho các màn chi tiết/overlay — chỉ giữ `actions` do màn tự truyền.
  final bool showDefaultActions;

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
    this.showDefaultActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: customAppBar ??
          (showAppBar
              ? AppBar(
                  title: Text(title),
                  actions: showDefaultActions
                      ? [
                          ...?actions,
                          _NotificationBell(),
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
                                color: isDark
                                    ? AppColors.oceanBright
                                    : Colors.white,
                              ),
                            ),
                            onPressed: () =>
                                ref.read(themeProvider.notifier).toggle(),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
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
                                    user?.name.isNotEmpty == true
                                        ? user!.name[0].toUpperCase()
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
                        ]
                      : actions,
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
  // ── Nav items per role ─────────────────────────────────────────────
  // SALE (system): Tổng quan · Phòng · Lịch · Báo cáo.
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

  // OWNER: Tổng quan · Báo cáo · Thêm phòng (action) · Thông báo (action) ·
  // Quản lý. Bỏ Phòng + Lịch theo yêu cầu. "Thêm phòng"/"Thông báo" là action
  // (push overlay), không phải tab — nên không có trạng thái chọn.
  static const _ownerNavItems = <_NavItem>[
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Tổng quan',
      route: '/dashboard',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Báo cáo',
      route: '/reports',
    ),
    _NavItem(
      icon: Icons.add_home_outlined,
      activeIcon: Icons.add_home_rounded,
      label: 'Thêm phòng',
      action: _NavAction.addProperty,
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Thông báo',
      action: _NavAction.notifications,
    ),
    _adminExtraItem,
  ];

  List<_NavItem> _getNavItems(UserModel? user) {
    if (user == null) return _staffNavItems;
    if (user.isOwner) return _ownerNavItems;
    if (user.isAdmin) return [..._staffNavItems, _adminExtraItem];
    return _staffNavItems;
  }

  /// Chỉ số tab đang chọn — suy TỪ ROUTE hiện tại (bền vững khi mỗi role có
  /// bộ tab khác nhau/khác thứ tự). Action item (route null) không bao giờ
  /// được chọn. Fallback về selectedIndex do màn truyền nếu route không khớp.
  int _selectedIndex(List<_NavItem> items) {
    final loc =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    for (var i = 0; i < items.length; i++) {
      final r = items[i].route;
      if (r != null && (loc == r || loc.startsWith('$r/'))) return i;
    }
    final idx = widget.selectedIndex;
    return (idx >= 0 && idx < items.length) ? idx : 0;
  }

  Future<void> _handleAction(_NavAction action) async {
    switch (action) {
      case _NavAction.notifications:
        context.push('/notifications');
      case _NavAction.addProperty:
        // Cùng gate với nút "Thêm phòng" ở dashboard: KYC (router) + tài khoản
        // nhận tiền đã duyệt (popup). SALE/ADMIN không dùng nav này.
        final user = ref.read(currentUserProvider);
        final ok = await ensureBankForPropertyCreate(context, user);
        if (ok && mounted) {
          context.push('/properties/new');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final navItems = _getNavItems(user);
    final current = _selectedIndex(navItems);

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
                return _buildNavItem(navItems[i], isSelected: i == current);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, {required bool isSelected}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.oceanBright : AppColors.ocean;
    final inactiveColor = isDark ? AppColors.darkHint : AppColors.slate;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (item.action != null) {
            _handleAction(item.action!);
          } else if (item.route != null) {
            context.go(item.route!);
          }
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

/// Hành động của nav item không phải tab (không có route/trang cố định).
enum _NavAction { addProperty, notifications }

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? route; // null nếu là action
  final _NavAction? action; // != null → push overlay thay vì đổi tab
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.route,
    this.action,
  });
}
