import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/homestay_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/homestay_controller.dart';

class HomestayListScreen extends ConsumerWidget {
  const HomestayListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homestaysAsync = ref.watch(homestayListProvider);
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;

    return AppScaffold(
      title: 'Homestay',
      selectedIndex: 2,
      floatingActionButton: user?.canEdit == true
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.oceanMid, AppColors.ocean],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ocean.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/homestays/new'),
                icon: const Icon(Icons.add_home_work_rounded, size: 20),
                label: Text('Thêm mới',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                highlightElevation: 0,
              ),
            )
          : null,
      body: homestaysAsync.when(
        loading: () =>
            SkeletonList(skeleton: const HomestayCardSkeleton(), count: 5),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(homestayListProvider),
        ),
        data: (homestays) {
          if (homestays.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.home_work_outlined,
              message: 'Chưa có homestay nào',
              subMessage:
                  user?.canEdit == true ? 'Nhấn + để thêm homestay' : null,
              onAction: user?.canEdit == true
                  ? () => context.push('/homestays/new')
                  : null,
              actionLabel: 'Thêm homestay',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(homestayListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
              itemCount: homestays.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _HomestayCard(
                homestay: homestays[i],
                index: i,
                isAdmin: isAdmin,
                canEdit: user?.canEdit ?? false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomestayCard extends StatefulWidget {
  final HomestayModel homestay;
  final int index;
  final bool isAdmin;
  final bool canEdit;

  const _HomestayCard({
    required this.homestay,
    required this.index,
    required this.isAdmin,
    required this.canEdit,
  });

  @override
  State<_HomestayCard> createState() => _HomestayCardState();
}

class _HomestayCardState extends State<_HomestayCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.homestay;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push('/homestays/${h.id}');
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          elevation: 2,
          shadowColor: colors.shadow.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // ── Icon ────────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.home_work_rounded,
                      color: AppColors.primary, size: 26),
                ),

                const SizedBox(width: AppSpacing.md),

                // ── Info ─────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + active badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              h.name,
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!h.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.outline.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                'Tạm nghỉ',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10,
                                  color: colors.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Address
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: colors.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              h.address,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Room count + owner (admin only)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              '${h.roomCount ?? 0} phòng',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.isAdmin) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(Icons.person_outline_rounded,
                                size: 12,
                                color: colors.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 3),
                            Text(
                              h.ownerName,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: colors.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Edit button ──────────────────────────────────────
                if (widget.canEdit)
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: colors.primary, size: 20),
                    onPressed: () => context.push('/homestays/${h.id}'),
                    tooltip: 'Chỉnh sửa',
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0);
  }
}
