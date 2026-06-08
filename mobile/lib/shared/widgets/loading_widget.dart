import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_toast.dart';

// ─── Loading Spinner ──────────────────────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.ocean),
      );
}

// ─── Shimmer helper ───────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

Widget _shimmerWrap({required Widget child, required BuildContext context}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Shimmer.fromColors(
    baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
    highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
    child: child,
  );
}

// ─── Room Card Skeleton ───────────────────────────────────────────────────────
class RoomCardSkeleton extends StatelessWidget {
  const RoomCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        context: context,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 180, height: 16),
                    const SizedBox(height: AppSpacing.sm),
                    _ShimmerBox(width: 120, height: 12),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _ShimmerBox(width: 60, height: 20, radius: 20),
                        const SizedBox(width: 6),
                        _ShimmerBox(width: 60, height: 20, radius: 20),
                        const SizedBox(width: 6),
                        _ShimmerBox(width: 60, height: 20, radius: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Booking Card Skeleton ────────────────────────────────────────────────────
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        context: context,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 160, height: 16),
                      const SizedBox(height: AppSpacing.sm),
                      _ShimmerBox(width: 120, height: 12),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _ShimmerBox(width: 80, height: 12),
                          const SizedBox(width: AppSpacing.md),
                          _ShimmerBox(width: 80, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                _ShimmerBox(width: 64, height: 24, radius: AppRadius.full),
              ],
            ),
          ),
        ),
      );
}

// ─── Homestay Card Skeleton ───────────────────────────────────────────────────
class HomestayCardSkeleton extends StatelessWidget {
  const HomestayCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        context: context,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 160, height: 16),
                      const SizedBox(height: AppSpacing.sm),
                      _ShimmerBox(width: 220, height: 12),
                      const SizedBox(height: AppSpacing.xs),
                      _ShimmerBox(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── User Card Skeleton ───────────────────────────────────────────────────────
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        context: context,
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: _ShimmerBox(width: 140, height: 14),
          ),
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: _ShimmerBox(width: 100, height: 12),
            ),
          ),
          trailing: _ShimmerBox(width: 52, height: 22, radius: AppRadius.full),
        ),
      );
}

// ─── Detail Skeleton ──────────────────────────────────────────────────────────
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _shimmerWrap(
        context: context,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ShimmerBox(width: 220, height: 22),
              const SizedBox(height: AppSpacing.sm),
              _ShimmerBox(width: 160, height: 14),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                      child: _ShimmerBox(
                          width: double.infinity,
                          height: 72,
                          radius: AppRadius.md)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: _ShimmerBox(
                          width: double.infinity,
                          height: 72,
                          radius: AppRadius.md)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                      child: _ShimmerBox(
                          width: double.infinity,
                          height: 72,
                          radius: AppRadius.md)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: _ShimmerBox(
                          width: double.infinity,
                          height: 72,
                          radius: AppRadius.md)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _ShimmerBox(width: 140, height: 16),
              const SizedBox(height: AppSpacing.sm),
              _ShimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: AppSpacing.xs),
              _ShimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: AppSpacing.xs),
              _ShimmerBox(width: 200, height: 14),
            ],
          ),
        ),
      );
}

// ─── Skeleton List Helper ─────────────────────────────────────────────────────
class SkeletonList extends StatelessWidget {
  final Widget skeleton;
  final int count;

  const SkeletonList({super.key, required this.skeleton, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => skeleton
          .animate(delay: Duration(milliseconds: i * 60))
          .fadeIn(duration: 300.ms),
    );
  }
}

// ─── Empty State Widget ───────────────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subMessage,
    this.icon = Icons.inbox_rounded,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.oceanLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.ocean.withValues(alpha: 0.5),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0),
            if (subMessage != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subMessage!,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
            ],
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Thêm mới'),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error State Widget ───────────────────────────────────────────────────────
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.coral.withValues(alpha: 0.7),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Có lỗi xảy ra',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 150.ms).fadeIn(duration: 300.ms),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── App SnackBar helper ──────────────────────────────────────────────────────
/// Thông báo dạng toast (toastify). Delegate sang [AppToast] để toàn bộ dự án
/// (21+ nơi đang gọi `AppSnackBar.*`) dùng chung 1 kiểu toast nổi từ trên xuống.
class AppSnackBar {
  static void success(BuildContext context, String message) =>
      AppToast.success(context, message);

  static void error(BuildContext context, String message) =>
      AppToast.error(context, message);

  static void info(BuildContext context, String message) =>
      AppToast.info(context, message);
}

// ─── Legacy aliases ───────────────────────────────────────────────────────────
// ignore: camel_case_types
typedef ErrorWidget_ = ErrorStateWidget;
typedef EmptyWidget = EmptyStateWidget;
