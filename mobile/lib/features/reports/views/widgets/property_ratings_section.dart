import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/report_models.dart';

/// Section "ĐÁNH GIÁ CĂN" — overview + per-property ratings + recent reviews.
///
/// Anatomy:
/// - Top: overall avg rating (big star) + total review count + 5-star
///   distribution bars (như Booking.com style)
/// - Mid: list "Phòng được yêu thích nhất" — top 3 phòng theo avgRating
///   (chỉ phòng có ≥ 3 review để tránh noise từ phòng mới)
/// - Bottom: 3 review gần nhất (preview) — customer name + rating + comment
class PropertyRatingsSection extends StatelessWidget {
  final List<PropertyRating> ratings;
  final List<CustomerReview> reviews;
  final double overallAvgRating;
  final int overallTotalReviews;
  final Map<int, int> overallDistribution;

  const PropertyRatingsSection({
    super.key,
    required this.ratings,
    required this.reviews,
    required this.overallAvgRating,
    required this.overallTotalReviews,
    required this.overallDistribution,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (ratings.isEmpty && reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border.all(color: colors.borderDefault),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(Icons.star_border_rounded,
                size: 40, color: colors.textTertiary),
            const SizedBox(height: 8),
            Text(
              'Chưa có đánh giá',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Khách sẽ đánh giá sau khi check-out',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _OverviewCard(
          avgRating: overallAvgRating,
          totalReviews: overallTotalReviews,
          distribution: overallDistribution,
        ),
        if (ratings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TopRatedRoomsCard(ratings: _topRated(ratings)),
        ],
        if (reviews.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RecentReviewsCard(reviews: reviews.take(3).toList()),
        ],
      ],
    );
  }

  /// Lọc + sort top 3 phòng có rating cao nhất, ≥ 3 review để loại noise.
  List<PropertyRating> _topRated(List<PropertyRating> all) {
    final filtered = all.where((p) => p.totalReviews >= 3).toList();
    filtered.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    return filtered.take(3).toList();
  }
}

// ─── Overview card ─────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final double avgRating;
  final int totalReviews;
  final Map<int, int> distribution;

  const _OverviewCard({
    required this.avgRating,
    required this.totalReviews,
    required this.distribution,
  });

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big rating bên trái
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              _StarRow(rating: avgRating, size: 14),
              const SizedBox(height: 4),
              Text(
                '$totalReviews đánh giá',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Distribution bars bên phải
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final pct = totalReviews == 0 ? 0.0 : count / totalReviews;
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
                      Icon(Icons.star, size: 9, color: AppColors.gold500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: colors.bgSurfaceContainer,
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.gold500),
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
    );
  }
}

// ─── Top rated rooms card ──────────────────────────────────────────────────

class _TopRatedRoomsCard extends StatelessWidget {
  final List<PropertyRating> ratings;
  const _TopRatedRoomsCard({required this.ratings});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              Icon(Icons.emoji_events_rounded,
                  size: 16, color: AppColors.gold500),
              const SizedBox(width: 6),
              Text(
                'Phòng được yêu thích nhất',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ratings.asMap().entries.map((e) {
            final isLast = e.key == ratings.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: _TopRatedRow(
                rank: e.key + 1,
                rating: e.value,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TopRatedRow extends StatelessWidget {
  final int rank;
  final PropertyRating rating;

  const _TopRatedRow({required this.rank, required this.rating});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppColors.gold500.withValues(alpha: 0.18)
                : colors.bgSurfaceContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: rank == 1 ? AppColors.gold500 : colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rating.propertyName,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${rating.totalReviews} đánh giá',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.gold500.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 11, color: AppColors.gold500),
              const SizedBox(width: 3),
              Text(
                rating.avgRating.toStringAsFixed(1),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Recent reviews card ───────────────────────────────────────────────────

class _RecentReviewsCard extends StatelessWidget {
  final List<CustomerReview> reviews;
  const _RecentReviewsCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
          Text(
            'Đánh giá gần đây',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...reviews.asMap().entries.map((e) {
            final isLast = e.key == reviews.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: _ReviewItem(review: e.value),
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final CustomerReview review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = review.customerName.isEmpty
        ? '?'
        : review.customerName[0].toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.customerName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _StarRow(rating: review.rating, size: 11),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${review.propertyName} · ${_timeAgo(review.createdAt)}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                review.comment,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${dt.day}/${dt.month}';
    if (diff.inDays >= 1) return '${diff.inDays} ngày trước';
    if (diff.inHours >= 1) return '${diff.inHours} giờ trước';
    return 'Vừa xong';
  }
}

// ─── Star row helper ───────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating; // 0..5
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
