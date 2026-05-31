import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../properties/controllers/property_controller.dart';
import '../controllers/kyc_approval_controller.dart';
import '../controllers/user_controller.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;
    final usersAsync = ref.watch(staffListProvider);
    final homestaysAsync = ref.watch(homestayListProvider(true));
    final bookingsAsync = ref.watch(bookingListProvider(null));
    final pendingKycCount = ref.watch(pendingKycCountProvider).valueOrNull ?? 0;

    return AppScaffold(
      title: '',
      selectedIndex: 4,
      showAppBar: false,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.jade900, AppColors.jade500],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -50,
                  top: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.jade300.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -40,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold500.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin ? 'Quản lý hệ thống' : 'Quản lý',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAdmin
                                ? 'Toàn quyền quản trị'
                                : 'Phòng & nhân viên của tôi',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AvatarBtn(
                      userName: user?.name ?? user?.phone ?? '',
                      onTap: () => context.push('/profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: colors.brand,
              onRefresh: () async {
                ref.invalidate(staffListProvider);
                ref.invalidate(homestayListProvider(true));
                ref.invalidate(bookingListProvider(null));
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Summary KPI Cards (2x2) ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          icon: Icons.people_rounded,
                          iconBg: AppColors.jade50,
                          iconColor: colors.brand,
                          label: 'Nhân viên',
                          asyncValue: usersAsync.whenData(
                            (users) => '${users.length}',
                          ),
                          sub: usersAsync.whenOrNull(
                                data: (users) =>
                                    '${users.where((u) => u.isActive).length} hoạt động',
                              ) ??
                              '',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          icon: Icons.villa_rounded,
                          iconBg: colors.successBg,
                          iconColor: colors.success,
                          label: 'Villa',
                          asyncValue: homestaysAsync.whenData(
                            (list) =>
                                '${list.where((h) => h.type == 0).length}',
                          ),
                          sub: 'Biệt thự',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          icon: Icons.home_work_rounded,
                          iconBg: AppColors.jade50,
                          iconColor: colors.brandLight,
                          label: 'Phòng',
                          asyncValue: homestaysAsync.whenData(
                            (list) =>
                                '${list.where((h) => h.type != 0).length}',
                          ),
                          sub: 'Cơ sở lưu trú',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          icon: Icons.book_rounded,
                          iconBg: AppColors.gold50,
                          iconColor: AppColors.gold700,
                          label: 'Booking',
                          asyncValue: bookingsAsync.whenData(
                            (list) => '${list.length}',
                          ),
                          sub: 'Tổng đặt phòng',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Management section.
                  Text(
                    isAdmin ? 'QUẢN LÝ HỆ THỐNG' : 'QUẢN LÝ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _MenuCard(
                    icon: Icons.people_rounded,
                    iconBg: AppColors.jade50,
                    iconColor: colors.brand,
                    title: isAdmin ? 'Quản lý nhân viên' : 'Nhân viên của tôi',
                    subtitle: isAdmin
                        ? 'Thêm, sửa, vô hiệu hoá tài khoản'
                        : 'Thêm, gỡ nhân viên khỏi đội',
                    trailing: usersAsync.whenOrNull(
                      data: (users) => '${users.length} người',
                    ),
                    onTap: () => context.push('/admin/users'),
                  ),

                  const SizedBox(height: 10),

                  _MenuCard(
                    icon: Icons.home_work_rounded,
                    iconBg: AppColors.jade50,
                    iconColor: colors.brandLight,
                    title: 'Quản lý phòng',
                    subtitle: 'Villa, Homestay, Khách sạn',
                    trailing: homestaysAsync.whenOrNull(
                      data: (list) => '${list.length} phòng',
                    ),
                    onTap: () => context.push('/admin/rooms'),
                  ),

                  const SizedBox(height: 10),

                  _MenuCard(
                    icon: Icons.book_rounded,
                    iconBg: AppColors.gold50,
                    iconColor: AppColors.gold700,
                    title: 'Quản lý booking',
                    subtitle: 'Xem, xác nhận, huỷ đặt phòng',
                    trailing: bookingsAsync.whenOrNull(
                      data: (list) => '${list.length} booking',
                    ),
                    onTap: () => context.push('/bookings'),
                  ),

                  const SizedBox(height: 10),

                  _MenuCard(
                    icon: Icons.calendar_month_rounded,
                    iconBg: colors.successBg,
                    iconColor: colors.success,
                    title: 'Lịch phòng',
                    subtitle: 'Quản lý lịch lock/mở phòng của chủ nhà',
                    onTap: () => context.push('/admin/owner-calendar'),
                  ),

                  const SizedBox(height: 10),

                  _MenuCard(
                    icon: Icons.tune_rounded,
                    iconBg: AppColors.jade50,
                    iconColor: AppColors.jade700,
                    title: 'Phân quyền vai trò',
                    subtitle: 'Cấu hình quyền truy cập cho từng vai trò',
                    onTap: () => context.push('/admin/role-permissions'),
                  ),

                  // OWNER subscription entry — visible only for OWNER (admins
                  // don't subscribe). Tap → /verify/subscription-detail which
                  // hosts the "Chọn gói + Mua qua App Store" CTA (iOS) or the
                  // renew flow (Android).
                  if (user?.isOwner ?? false) ...[
                    const SizedBox(height: 10),
                    _MenuCard(
                      icon: Icons.workspace_premium_rounded,
                      iconBg: AppColors.goldBg,
                      iconColor: AppColors.goldText,
                      title: 'Gói đăng ký',
                      subtitle:
                          'Nâng cấp, gia hạn, hoặc xem lịch sử thanh toán',
                      onTap: () => context.push('/verify/subscription-detail'),
                    ),
                  ],

                  if (isAdmin) ...[
                    const SizedBox(height: 10),
                    _MenuCard(
                      icon: Icons.verified_user_rounded,
                      iconBg: AppColors.goldBg,
                      iconColor: AppColors.goldText,
                      title: 'Duyệt KYC',
                      subtitle: 'Xét duyệt CCCD + selfie chủ nhà mới',
                      trailing: pendingKycCount > 0
                          ? '$pendingKycCount chờ'
                          : 'Trống',
                      onTap: () => context.push('/admin/kyc'),
                    ),
                    const SizedBox(height: 10),
                    _MenuCard(
                      icon: Icons.report_gmailerrorred_rounded,
                      iconBg: colors.error.withValues(alpha: 0.1),
                      iconColor: colors.error,
                      title: 'Báo cáo vi phạm',
                      subtitle: 'Danh sách tố cáo và xử lý abuse',
                      onTap: () => context.push('/admin/abuse-reports'),
                    ),
                    const SizedBox(height: 10),
                    _MenuCard(
                      icon: Icons.history_rounded,
                      iconBg: colors.bgSurfaceContainer,
                      iconColor: colors.textSecondary,
                      title: 'Lịch sử moderation',
                      subtitle: 'Audit các hành động kiểm duyệt',
                      onTap: () => context.push('/admin/moderation-audit'),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Quick Actions ───────────────────────────
                  Text(
                    'THAO TÁC NHANH',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (isAdmin) ...[
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.person_add_rounded,
                            label: 'Thêm\nnhân viên',
                            color: colors.brand,
                            onTap: () => context.push('/admin/users/new'),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_home_work_rounded,
                          label: 'Thêm\nphòng',
                          color: colors.brandLight,
                          onTap: () => context.push('/properties/new'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recent staff.
                  Text(
                    'NHÂN VIÊN GẦN ĐÂY',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  usersAsync.when(
                    loading: () => const SizedBox(
                      height: 80,
                      child: Center(child: LoadingWidget()),
                    ),
                    error: (e, _) => ErrorStateWidget(
                      message: e.toString().replaceAll('Exception: ', ''),
                      onRetry: () => ref.invalidate(staffListProvider),
                    ),
                    data: (users) {
                      if (users.isEmpty) {
                        return const EmptyStateWidget(
                          icon: Icons.people_outline_rounded,
                          message: 'Chưa có nhân viên',
                        );
                      }
                      final recent = users.take(5).toList();
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.30 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < recent.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  color: colors.borderDefault,
                                  indent: 60,
                                ),
                              _UserRow(
                                user: recent[i],
                                onTap: () => context.push(
                                  '/admin/users/${recent[i].id}/edit',
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  // ── View all button ─────────────────────────
                  usersAsync.whenOrNull(
                        data: (users) => users.length > 5
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () => context.push('/admin/users'),
                                  child: Text(
                                    'Xem tất cả ${users.length} nhân viên →',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.brand,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ) ??
                      const SizedBox.shrink(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI Card ────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final AsyncValue<String> asyncValue;
  final String sub;

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.asyncValue,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          asyncValue.when(
            data: (value) => Text(
              value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            loading: () => SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.brand,
              ),
            ),
            error: (_, __) => Text(
              '--',
              style: GoogleFonts.beVietnamPro(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Card ───────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    trailing!,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action ────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User Row ────────────────────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final dynamic user;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roleColor = AppHelpers.roleColor(user.role);
    final roleLabel = AppHelpers.roleLabel(user.role);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: roleColor.withValues(alpha: 0.12),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: GoogleFonts.beVietnamPro(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.phone,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                roleLabel,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
            if (!user.isActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Avatar Button ─────────────────────────────────────────────────────────────
class _AvatarBtn extends StatelessWidget {
  final String userName;
  final VoidCallback onTap;

  const _AvatarBtn({required this.userName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              colors: [AppColors.jade300, AppColors.gold500]),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Center(
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
