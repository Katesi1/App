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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,

          // Theme toggle
          IconButton(
            tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: colors.primary,
              ),
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),

          // User avatar + menu
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: PopupMenuButton<String>(
              tooltip: 'Tài khoản',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: _roleColor(user?.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
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
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          showBottomNav ? _BottomNav(selectedIndex: selectedIndex ?? 0) : null,
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
    final isAdmin = user?.isAdmin ?? false;
    final canEdit = user?.canEdit ?? false;
    final colors = Theme.of(context).colorScheme;

    final items = <_NavItem>[
      const _NavItem(
          icon: Icons.bed_outlined,
          activeIcon: Icons.bed_rounded,
          label: 'Phòng',
          route: '/rooms'),
      const _NavItem(
          icon: Icons.event_note_outlined,
          activeIcon: Icons.event_note_rounded,
          label: 'Booking',
          route: '/bookings'),
      if (canEdit)
        const _NavItem(
            icon: Icons.home_work_outlined,
            activeIcon: Icons.home_work_rounded,
            label: 'Homestay',
            route: '/homestays'),
      if (isAdmin)
        const _NavItem(
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            label: 'Nhân viên',
            route: '/admin/users'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = _current == i;

              return Expanded(
                child: _NavItemWidget(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _current = i);
                    context.go(item.route);
                  },
                ),
              );
            }).toList(),
          ),
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
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.route});
}

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget(
      {required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
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
          ).animate(target: isSelected ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 200.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? colors.primary : colors.outline,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
