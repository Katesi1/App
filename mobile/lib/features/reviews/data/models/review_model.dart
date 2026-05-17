import 'package:equatable/equatable.dart';

/// 1 review của khách hàng — match `GET /properties/:id/reviews` items[].
/// 6 tiêu chí 1-5 sao, comment + photos optional, owner có thể reply.
class ReviewModel extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final int cleanliness;
  final int location;
  final int amenities;
  final int service;
  final int value;
  final int accuracy;

  /// Avg 6 tiêu chí — backend tính sẵn (vd 4.83).
  final double avgRating;

  final String? comment;
  final List<String> photos;
  final String? ownerReply;
  final DateTime? ownerReplyAt;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.cleanliness,
    required this.location,
    required this.amenities,
    required this.service,
    required this.value,
    required this.accuracy,
    required this.avgRating,
    this.comment,
    this.photos = const [],
    this.ownerReply,
    this.ownerReplyAt,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? const {};
    return ReviewModel(
      id: json['id'] as String,
      customerId: customer['id'] as String? ?? '',
      customerName: customer['name'] as String? ?? '',
      customerAvatar: customer['avatar'] as String?,
      cleanliness: (json['cleanliness'] as num?)?.toInt() ?? 0,
      location: (json['location'] as num?)?.toInt() ?? 0,
      amenities: (json['amenities'] as num?)?.toInt() ?? 0,
      service: (json['service'] as num?)?.toInt() ?? 0,
      value: (json['value'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String?,
      photos: (json['photos'] as List?)?.cast<String>() ?? const [],
      ownerReply: json['ownerReply'] as String?,
      ownerReplyAt: json['ownerReplyAt'] != null
          ? DateTime.tryParse(json['ownerReplyAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  ReviewModel copyWith({
    String? ownerReply,
    DateTime? ownerReplyAt,
  }) =>
      ReviewModel(
        id: id,
        customerId: customerId,
        customerName: customerName,
        customerAvatar: customerAvatar,
        cleanliness: cleanliness,
        location: location,
        amenities: amenities,
        service: service,
        value: value,
        accuracy: accuracy,
        avgRating: avgRating,
        comment: comment,
        photos: photos,
        ownerReply: ownerReply ?? this.ownerReply,
        ownerReplyAt: ownerReplyAt ?? this.ownerReplyAt,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        customerId,
        avgRating,
        comment,
        ownerReply,
        ownerReplyAt,
        createdAt,
      ];
}

/// Summary của 1 property — luôn tính trên TẤT CẢ review visible (không
/// bị ảnh hưởng bởi `minRating` filter — xem spec section 2.2 lưu ý).
class PropertyReviewSummary extends Equatable {
  final double avgRating;
  final int totalReviews;
  final Map<int, int> distribution; // key = sao (1..5)
  final ReviewBreakdown breakdown;

  const PropertyReviewSummary({
    this.avgRating = 0,
    this.totalReviews = 0,
    this.distribution = const {},
    this.breakdown = const ReviewBreakdown(),
  });

  bool get isEmpty => totalReviews == 0;

  factory PropertyReviewSummary.fromJson(Map<String, dynamic> json) =>
      PropertyReviewSummary(
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
        totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
        distribution: _parseDistribution(json['distribution']),
        breakdown: json['breakdown'] is Map<String, dynamic>
            ? ReviewBreakdown.fromJson(
                json['breakdown'] as Map<String, dynamic>)
            : const ReviewBreakdown(),
      );

  @override
  List<Object?> get props => [avgRating, totalReviews, distribution, breakdown];
}

/// Breakdown 6 tiêu chí (avg). Cùng shape với
/// `features/reports/data/RatingBreakdown` nhưng đặt riêng để feature
/// `reviews` không phải import chéo `reports`.
class ReviewBreakdown extends Equatable {
  final double cleanliness;
  final double location;
  final double amenities;
  final double service;
  final double value;
  final double accuracy;

  const ReviewBreakdown({
    this.cleanliness = 0,
    this.location = 0,
    this.amenities = 0,
    this.service = 0,
    this.value = 0,
    this.accuracy = 0,
  });

  factory ReviewBreakdown.fromJson(Map<String, dynamic> json) =>
      ReviewBreakdown(
        cleanliness: (json['cleanliness'] as num?)?.toDouble() ?? 0,
        location: (json['location'] as num?)?.toDouble() ?? 0,
        amenities: (json['amenities'] as num?)?.toDouble() ?? 0,
        service: (json['service'] as num?)?.toDouble() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      );

  /// `(label, score)` cho UI render bars.
  List<({String label, double score})> get items => [
        (label: 'Sạch sẽ', score: cleanliness),
        (label: 'Vị trí', score: location),
        (label: 'Tiện nghi', score: amenities),
        (label: 'Dịch vụ', score: service),
        (label: 'Giá trị', score: value),
        (label: 'Đúng mô tả', score: accuracy),
      ];

  bool get isEmpty =>
      cleanliness == 0 &&
      location == 0 &&
      amenities == 0 &&
      service == 0 &&
      value == 0 &&
      accuracy == 0;

  @override
  List<Object?> get props =>
      [cleanliness, location, amenities, service, value, accuracy];
}

/// Wrap response `GET /properties/:id/reviews`.
class PropertyReviewsPage extends Equatable {
  final PropertyReviewSummary summary;
  final List<ReviewModel> items;
  final int page;
  final int pageSize;
  final int total;

  const PropertyReviewsPage({
    required this.summary,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory PropertyReviewsPage.fromJson(Map<String, dynamic> json) =>
      PropertyReviewsPage(
        summary: json['summary'] is Map<String, dynamic>
            ? PropertyReviewSummary.fromJson(
                json['summary'] as Map<String, dynamic>)
            : const PropertyReviewSummary(),
        items: (json['items'] as List?)
                ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        page: (json['page'] as num?)?.toInt() ?? 1,
        pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [summary, items, page, pageSize, total];
}

/// Sort options khi xem reviews. Map sang query `sort=` của backend.
enum ReviewSort { newest, oldest, highest, lowest }

extension ReviewSortX on ReviewSort {
  String get apiValue => switch (this) {
        ReviewSort.newest => 'newest',
        ReviewSort.oldest => 'oldest',
        ReviewSort.highest => 'highest',
        ReviewSort.lowest => 'lowest',
      };

  String get label => switch (this) {
        ReviewSort.newest => 'Mới nhất',
        ReviewSort.oldest => 'Cũ nhất',
        ReviewSort.highest => 'Cao nhất',
        ReviewSort.lowest => 'Thấp nhất',
      };
}

/// Payload cho `POST /properties/:id/reviews`. Validate 1-5 cho mỗi tiêu chí.
class CreateReviewPayload {
  final String bookingId;
  final int cleanliness;
  final int location;
  final int amenities;
  final int service;
  final int value;
  final int accuracy;
  final String? comment;
  final List<String> photos;

  const CreateReviewPayload({
    required this.bookingId,
    required this.cleanliness,
    required this.location,
    required this.amenities,
    required this.service,
    required this.value,
    required this.accuracy,
    this.comment,
    this.photos = const [],
  });

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'cleanliness': cleanliness,
        'location': location,
        'amenities': amenities,
        'service': service,
        'value': value,
        'accuracy': accuracy,
        if (comment != null && comment!.trim().isNotEmpty)
          'comment': comment!.trim(),
        if (photos.isNotEmpty) 'photos': photos,
      };
}

/// Filter params cho list provider.
class ReviewListParams extends Equatable {
  final String propertyId;
  final int page;
  final int pageSize;
  final ReviewSort sort;
  final int? minRating;

  const ReviewListParams({
    required this.propertyId,
    this.page = 1,
    this.pageSize = 20,
    this.sort = ReviewSort.newest,
    this.minRating,
  });

  ReviewListParams copyWith({
    int? page,
    int? pageSize,
    ReviewSort? sort,
    int? minRating,
    bool clearMinRating = false,
  }) =>
      ReviewListParams(
        propertyId: propertyId,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
        sort: sort ?? this.sort,
        minRating: clearMinRating ? null : (minRating ?? this.minRating),
      );

  @override
  List<Object?> get props => [propertyId, page, pageSize, sort, minRating];
}

Map<int, int> _parseDistribution(dynamic raw) {
  if (raw is! Map) return const {};
  final result = <int, int>{};
  raw.forEach((k, v) {
    final star = int.tryParse('$k');
    final count = (v is num) ? v.toInt() : int.tryParse('$v');
    if (star != null && count != null) result[star] = count;
  });
  return result;
}
