import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/review_controller.dart';
import 'widgets/owner_reply_modal.dart';

/// List public reviews của 1 property + summary header + sort/filter +
/// pagination. Public — không cần token. OWNER cùng property thấy nút
/// "Trả lời" trên mỗi review.
class PropertyReviewsScreen extends ConsumerWidget {
  final String propertyId;
  final String? propertyName;

  const PropertyReviewsScreen({
    super.key,
    required this.propertyId,
    this.propertyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final params = ref.watch(reviewListParamsProvider(propertyId));
    final pageAsync = ref.watch(propertyReviewsProvider(params));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          propertyName != null && propertyName!.isNotEmpty
              ? 'Đánh giá: $propertyName'
              : 'Đánh giá khách',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: pageAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(propertyReviewsProvider(params)),
        ),
        data: (page) => RefreshIndicator(
          color: colors.brand,
          onRefresh: () async =>
              ref.invalidate(propertyReviewsProvider(params)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (!page.summary.isEmpty) _SummaryCard(summary: page.summary),
              const SizedBox(height: AppSpacing.md),
              _SortFilterBar(
                params: params,
                onChanged: (next) => ref
                    .read(reviewListParamsProvider(propertyId).notifier)
                    .state = next,
              ),
              const SizedBox(height: 12),
              if (page.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: EmptyStateWidget(
                    icon: Icons.rate_review_outlined,
                    message: 'Chưa có đánh giá nào',
                  ),
                )
              else
                ..._buildReviewItems(context, ref, page),
              const SizedBox(height: 12),
              if (_totalPages(page) > 1)
                AppPaginationBar(
                  currentPage: params.page - 1,
                  totalPages: _totalPages(page),
                  onPrevious: params.page > 1
                      ? () => ref
                          .read(reviewListParamsProvider(propertyId).notifier)
                          .state = params.copyWith(page: params.page - 1)
                      : null,
                  onNext: params.page < _totalPages(page)
                      ? () => ref
                          .read(reviewListParamsProvider(propertyId).notifier)
                          .state = params.copyWith(page: params.page + 1)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _totalPages(PropertyReviewsPage page) =>
      (page.total / page.pageSize).ceil().clamp(1, 9999);

  List<Widget> _buildReviewItems(
    BuildContext context,
    WidgetRef ref,
    PropertyReviewsPage page,
  ) {
    final user = ref.read(currentUserProvider);
    // OWNER/ADMIN ở chế độ quản lý mới được trả lời. SALE chỉ xem.
    final canReply = user != null && (user.isOwner || user.isAdmin);

    return [
      for (final review in page.items) ...[
        _ReviewItemCard(
          review: review,
          canReply: canReply,
          onReply: () =>
              showOwnerReplyModal(context, propertyId: propertyId, review: review),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

// ─── Summary card (avg + distribution + breakdown) ────────────────────────────

class _SummaryCard extends StatelessWidget {
  final PropertyReviewSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.avgRating.toStringAsFixed(1),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StarRow(rating: summary.avgRating, size: 14),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalReviews} đánh giá',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = summary.distribution[star] ?? 0;
                    final pct = summary.totalReviews == 0
                        ? 0.0
                        : count / summary.totalReviews;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 10,
                            child: Text(
                              '$star',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                          Icon(Icons.star,
                              size: 9, color: AppColors.gold500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: colors.bgSurfaceContainer,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.gold500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$count',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          if (!summary.breakdown.isEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: colors.borderDefault, height: 1),
            const SizedBox(height: 12),
            ...summary.breakdown.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _BreakdownRow(label: item.label, score: item.score),
                )),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double score;
  const _BreakdownRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = (score / 5).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: colors.bgSurfaceContainer,
              valueColor: AlwaysStoppedAnimation(colors.brand),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ─── Sort + filter bar ────────────────────────────────────────────────────────

class _SortFilterBar extends StatelessWidget {
  final ReviewListParams params;
  final ValueChanged<ReviewListParams> onChanged;

  const _SortFilterBar({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showSortSheet(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border.all(color: colors.borderDefault),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort_rounded,
                      size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    params.sort.label,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more_rounded,
                      size: 16, color: colors.textTertiary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _showMinRatingSheet(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border.all(color: colors.borderDefault),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 16, color: AppColors.gold500),
                  const SizedBox(width: 6),
                  Text(
                    params.minRating == null
                        ? 'Tất cả sao'
                        : 'Từ ${params.minRating} sao',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more_rounded,
                      size: 16, color: colors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReviewSort.values.map((sort) {
              final selected = sort == params.sort;
              return ListTile(
                title: Text(
                  sort.label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? colors.brand : colors.textPrimary,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: colors.brand)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  // Reset về page 1 khi đổi sort.
                  onChanged(params.copyWith(sort: sort, page: 1));
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showMinRatingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        final options = <(int?, String)>[
          (null, 'Tất cả sao'),
          (5, 'Từ 5 sao'),
          (4, 'Từ 4 sao'),
          (3, 'Từ 3 sao'),
          (2, 'Từ 2 sao'),
          (1, 'Từ 1 sao'),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final selected = opt.$1 == params.minRating;
              return ListTile(
                title: Text(
                  opt.$2,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? colors.brand : colors.textPrimary,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: colors.brand)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(params.copyWith(
                    minRating: opt.$1,
                    clearMinRating: opt.$1 == null,
                    page: 1,
                  ));
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Review item card ─────────────────────────────────────────────────────────

class _ReviewItemCard extends StatelessWidget {
  final ReviewModel review;
  final bool canReply;
  final VoidCallback onReply;

  const _ReviewItemCard({
    required this.review,
    required this.canReply,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = review.customerName.isEmpty
        ? '?'
        : review.customerName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                avatar: review.customerAvatar,
                initials: initials,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StarRow(rating: review.avgRating, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          review.avgRating.toStringAsFixed(2),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textBrand,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${_formatDate(review.createdAt)}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: review.photos[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    memCacheWidth: 250,
                    placeholder: (_, __) => Container(
                      color: colors.bgSurfaceContainer,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: colors.bgSurfaceContainer,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_rounded,
                          color: colors.textTertiary, size: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (review.ownerReply != null &&
              review.ownerReply!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _OwnerReplyBlock(
              reply: review.ownerReply!,
              repliedAt: review.ownerReplyAt,
            ),
          ],
          if (canReply) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReply,
                icon: Icon(Icons.reply_rounded, size: 16, color: colors.brand),
                label: Text(
                  review.ownerReply == null ? 'Trả lời' : 'Sửa phản hồi',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.brand,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}';
  }
}

class _OwnerReplyBlock extends StatelessWidget {
  final String reply;
  final DateTime? repliedAt;

  const _OwnerReplyBlock({required this.reply, this.repliedAt});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: colors.brand, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded,
                  size: 12, color: colors.brand),
              const SizedBox(width: 4),
              Text(
                'Phản hồi từ chủ nhà',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.brand,
                ),
              ),
              if (repliedAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· ${_formatDate(repliedAt!)}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reply,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}';
  }
}

class _Avatar extends StatelessWidget {
  final String? avatar;
  final String initials;
  final double size;

  const _Avatar({
    required this.avatar,
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (avatar != null && avatar!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: 120,
          placeholder: (_, __) => _initialsAvatar(colors),
          errorWidget: (_, __, ___) => _initialsAvatar(colors),
        ),
      );
    }
    return _initialsAvatar(colors);
  }

  Widget _initialsAvatar(dynamic colors) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [colors.brand, AppColors.gold500],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.beVietnamPro(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRow({required this.rating, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= (i + 1);
        final half = !filled && rating > i && rating < i + 1;
        return Icon(
          filled
              ? Icons.star_rounded
              : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: size,
          color: AppColors.gold500,
        );
      }),
    );
  }
}
