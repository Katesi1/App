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
import '../../features/chat/controllers/chat_controller.dart';
import '../../features/properties/utils/create_property_flow.dart';

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
                    _ChatBell(),
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
                              colors: [AppColors.jade300, AppColors.gold500],
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
  // ── Nav item catalog ───────────────────────────────────────────────
  static const _dashboard = _NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Tổng quan',
    route: '/dashboard',
  );
  static const _rooms = _NavItem(
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment_rounded,
    label: 'Phòng',
    route: '/rooms',
  );
  static const _calendar = _NavItem(
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label: 'Lịch',
    route: '/calendar',
  );
  static const _reports = _NavItem(
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label: 'Báo cáo',
    route: '/reports',
  );
  static const _addProperty = _NavItem(
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
    label: 'Thêm phòng',
    route: '/properties/new',
    isAddProperty: true,
  );
  static const _notifications = _NavItem(
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications_rounded,
    label: 'Thông báo',
    route: '/notifications',
  );
  static const _management = _NavItem(
    icon: Icons.admin_panel_settings_outlined,
    activeIcon: Icons.admin_panel_settings_rounded,
    label: 'Quản lý',
    route: '/admin',
  );

  // ── Nav items theo role ────────────────────────────────────────────
  // OWNER: Tổng quan · Báo cáo · Thêm phòng · Thông báo · Quản lý
  //   (bỏ Phòng/Lịch — xem phòng ngay trên dashboard).
  // SALE:  Tổng quan · Báo cáo · Thông báo · Quản lý (không tạo được phòng).
  // ADMIN: giữ nav cũ (Tổng quan · Phòng · Lịch · Báo cáo · Quản lý).
  List<_NavItem> _getNavItems(UserModel? user) {
    if (user == null) return const [_dashboard, _rooms, _calendar, _reports];
    if (user.isAdmin) {
      return const [_dashboard, _rooms, _calendar, _reports, _management];
    }
    if (user.isOwner) {
      return const [
        _dashboard,
        _reports,
        _addProperty,
        _notifications,
        _management,
      ];
    }
    if (user.isSale) {
      return const [_dashboard, _reports, _notifications, _management];
    }
    return const [_dashboard, _rooms, _calendar, _reports];
  }

  /// Index tab đang chọn — suy từ route hiện tại (không phụ thuộc index cứng
  /// vì nav khác nhau theo role). Action "Thêm phòng" không bao giờ selected.
  int _selectedIndex(List<_NavItem> items) {
    final location = GoRouterState.of(context).matchedLocation;
    var best = -1;
    var bestLen = -1;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.isAddProperty) continue;
      final r = item.route;
      final matched = location == r || location.startsWith('$r/');
      if (matched && r.length > bestLen) {
        best = i;
        bestLen = r.length;
      }
    }
    return best < 0 ? 0 : best;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final navItems = _getNavItems(user);
    final current = _selectedIndex(navItems);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBg : AppColors.slate50,
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
                      : AppColors.slate900.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : AppColors.jade500.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(navItems.length, (i) {
                return _buildNavItem(i, navItems[i], current);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item, int current) {
    final isSelected = index == current;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.jadeText : AppColors.jade500;
    final inactiveColor = isDark ? AppColors.darkHint : AppColors.slate400;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (item.isAddProperty) {
            // Action: chạy luồng thêm phòng (cổng SĐT→KYC→bank→quota).
            startCreatePropertyFlow(context, ref);
            return;
          }
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
                        ? AppColors.jadeText.withValues(alpha: 0.15)
                        : AppColors.jade50
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

class _ChatBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(chatUnreadProvider);

    return IconButton(
      tooltip: 'Tin nhắn',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.forum_outlined),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.coral500,
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
      onPressed: () => context.push('/chat'),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);
    final count = unreadAsync.valueOrNull ?? 0;

    return IconButton(
      tooltip: 'Thông báo',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.coral500,
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

  /// True → tab là action "Thêm phòng": bấm chạy luồng tạo cơ sở thay vì
  /// điều hướng, và không bao giờ ở trạng thái selected.
  final bool isAddProperty;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.isAddProperty = false,
  });
}
