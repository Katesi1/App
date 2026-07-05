import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/subscription_locked_sheet.dart';
import '../../rooms/controllers/room_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/property_controller.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

class PropertyManageScreen extends ConsumerStatefulWidget {
  final String homestayId;
  const PropertyManageScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyManageScreen> createState() =>
      _PropertyManageScreenState();
}

class _PropertyManageScreenState extends ConsumerState<PropertyManageScreen> {
  bool _togglingActive = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return roomAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết')),
        body: ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(
            roomDetailProvider(widget.homestayId),
          ),
        ),
      ),
      data: (room) {
        return Scaffold(
          backgroundColor: colors.bgCanvas,
          body: Column(
            children: [
              // ── Gradient Header ──────────────────────────
              _GradientHeader(
                coverImageUrl: room.coverImageUrl,
                onBack: () => context.pop(),
                onEdit: () => context.push(
                  '/properties/${widget.homestayId}/info',
                ),
              ),

              // ── Content ──────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(roomDetailProvider(widget.homestayId));
                    await ref
                        .read(roomDetailProvider(widget.homestayId).future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // ── Name + subtitle ─────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${room.code} · ${room.name}',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                room.bedrooms == 0
                                    ? 'Studio'
                                    : '${room.bedrooms}PN',
                                '${room.bathrooms}WC',
                                '${room.standardGuests} người',
                                if (room.address != null &&
                                    room.address!.isNotEmpty)
                                  room.address!,
                              ].join(' · '),
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.05, end: 0),

                      const SizedBox(height: 16),

                      // ── Active toggle ───────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(
                              AppRadius.lg,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.30 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: room.isActive
                                      ? colors.success
                                      : colors.textTertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  room.isActive
                                      ? 'Đang hoạt động'
                                      : 'Tạm ngưng',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              _togglingActive
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.brand,
                                      ),
                                    )
                                  : Switch(
                                      value: room.isActive,
                                      activeTrackColor: colors.brand,
                                      onChanged: (val) => _toggleActive(val),
                                    ),
                            ],
                          ),
                        ),
                      ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                      const SizedBox(height: 20),

                      // ── Menu items ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(
                              AppRadius.lg,
                            ),
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
                              _MenuItem(
                                icon: Icons.camera_alt_outlined,
                                label: 'Ảnh',
                                trailing: '',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/images',
                                ),
                              ),
                              const _MenuDivider(),
                              _MenuItem(
                                icon: Icons.description_outlined,
                                label: 'Thông tin chi tiết',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/info',
                                ),
                              ),
                              const _MenuDivider(),
                              _MenuItem(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Tiện ích',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/amenities',
                                ),
                              ),
                              const _MenuDivider(),
                              _MenuItem(
                                icon: Icons.price_change_outlined,
                                label: 'Bảng giá',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/pricing',
                                ),
                              ),
                              const _MenuDivider(),
                              _MenuItem(
                                icon: Icons.room_service_outlined,
                                label: 'Dịch vụ trả phí',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/services',
                                ),
                              ),
                              const _MenuDivider(),
                              _MenuItem(
                                icon: Icons.rule_rounded,
                                label: 'Quy định',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/rules',
                                ),
                              ),
                              const _MenuDivider(),
                              _MenuItem(
                                icon: Icons.location_on_outlined,
                                label: 'Vị trí',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/location',
                                ),
                              ),
                              const _MenuDivider(),
                              _MenuItem(
                                icon: Icons.cancel_outlined,
                                label: 'Chính sách huỷ',
                                onTap: () => context.push(
                                  '/properties/${widget.homestayId}/cancellation',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                      const SizedBox(height: 24),

                      // ── Delete button (ADMIN + OWNER only) ──
                      if (ref.watch(currentUserProvider)?.canManageProperty ??
                          false)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteHomestay(context),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colors.error,
                            ),
                            label: Text(
                              'Xoá căn này',
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w600,
                                color: colors.error,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: colors.error,
                              ),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleActive(bool value) async {
    setState(() => _togglingActive = true);
    final notifier = ref.read(homestayActionsProvider.notifier);
    final ok = await notifier.toggleActive(widget.homestayId, value);
    if (mounted) {
      setState(() => _togglingActive = false);
      if (ok) {
        ref.invalidate(roomDetailProvider(widget.homestayId));
      } else {
        // BE 403 subscription.featureLocked → platform-aware sheet.
        final msg = ref.read(homestayActionsProvider).error?.toString();
        if (!SubscriptionLock.maybeHandle(context,
            code: notifier.lastErrorCode, message: msg)) {
          AppSnackBar.error(context, 'Không thể cập nhật trạng thái');
        }
      }
    }
  }

  Future<void> _deleteHomestay(BuildContext context) async {
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Xoá căn này',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xoá? Hành động này không thể hoàn tác.',
          style: GoogleFonts.beVietnamPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final result = await ref
        .read(homestayActionsProvider.notifier)
        .delete(widget.homestayId);
    if (!context.mounted) return;

    if (result) {
      ref.invalidate(roomListProvider);
      AppSnackBar.success(context, 'Đã xoá thành công');
      context.pop();
    } else {
      final error = ref.read(homestayActionsProvider);
      final msg = error.hasError
          ? error.error.toString().replaceAll('Exception: ', '')
          : 'Không thể xoá';
      AppSnackBar.error(context, msg);
    }
  }
}

// ─── Gradient Header ─────────────────────────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  final String? coverImageUrl;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _GradientHeader({
    this.coverImageUrl,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];

    return Stack(
      children: [
        // Background: cover image or gradient
        Container(
          width: double.infinity,
          height: topPadding + 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: headerGradient,
            ),
          ),
          child: coverImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: coverImageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  color: Colors.black.withValues(alpha: 0.3),
                  colorBlendMode: BlendMode.darken,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                )
              : null,
        ),
        // Top bar
        Positioned(
          top: topPadding,
          left: 8,
          right: 8,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: onBack,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Menu Item ───────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.brand, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  trailing!,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Divider ────────────────────────────────────────────────────────────
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Divider(
      height: 1,
      color: colors.borderDefault,
      indent: 52,
    );
  }
}
