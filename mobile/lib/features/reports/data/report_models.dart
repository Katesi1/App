import '../../../data/models/booking_model.dart';

/// One data point in the revenue trend chart (by day).
class RevenuePoint {
  final DateTime date;
  final int revenue;
  final int bookings;
  final double occupancy; // 0..1

  const RevenuePoint({
    required this.date,
    required this.revenue,
    required this.bookings,
    required this.occupancy,
  });

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => RevenuePoint(
        date: DateTime.parse(json['date'] as String),
        revenue: (json['revenue'] as num?)?.toInt() ?? 0,
        bookings: (json['bookings'] as num?)?.toInt() ?? 0,
        occupancy: (json['occupancy'] as num?)?.toDouble() ?? 0,
      );
}

/// Top rooms by revenue / occupancy (Phase 3).
class TopRoom {
  final String roomId;
  final String name;
  final String? coverImage;
  final int revenue;
  final int bookings;
  final double occupancy; // 0..1

  const TopRoom({
    required this.roomId,
    required this.name,
    this.coverImage,
    required this.revenue,
    required this.bookings,
    required this.occupancy,
  });

  factory TopRoom.fromJson(Map<String, dynamic> json) => TopRoom(
        roomId: json['roomId'] as String,
        name: json['name'] as String? ?? '',
        coverImage: json['coverImage'] as String?,
        revenue: (json['revenue'] as num?)?.toInt() ?? 0,
        bookings: (json['bookings'] as num?)?.toInt() ?? 0,
        occupancy: (json['occupancy'] as num?)?.toDouble() ?? 0,
      );
}

/// 6-criteria rating breakdown (Booking.com / Airbnb VN convention).
class RatingBreakdown {
  final double cleanliness;
  final double location;
  final double amenities;
  final double service;
  final double value;
  final double accuracy;

  const RatingBreakdown({
    this.cleanliness = 0,
    this.location = 0,
    this.amenities = 0,
    this.service = 0,
    this.value = 0,
    this.accuracy = 0,
  });

  factory RatingBreakdown.fromJson(Map<String, dynamic> json) =>
      RatingBreakdown(
        cleanliness: (json['cleanliness'] as num?)?.toDouble() ?? 0,
        location: (json['location'] as num?)?.toDouble() ?? 0,
        amenities: (json['amenities'] as num?)?.toDouble() ?? 0,
        service: (json['service'] as num?)?.toDouble() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      );

  /// Returns a list of `(label, score)` tuples for the UI bars.
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
}

/// Aggregate rating for one property.
class PropertyRating {
  final String propertyId;
  final String propertyName;
  final String? coverImage;
  final double avgRating; // 0..5 (avg of 6 criteria)
  final int totalReviews;
  final Map<int, int> distribution; // key = star count (1..5)
  final RatingBreakdown breakdown;

  const PropertyRating({
    required this.propertyId,
    required this.propertyName,
    this.coverImage,
    required this.avgRating,
    required this.totalReviews,
    this.distribution = const {},
    this.breakdown = const RatingBreakdown(),
  });

  factory PropertyRating.fromJson(Map<String, dynamic> json) => PropertyRating(
        propertyId: json['propertyId'] as String,
        propertyName: json['propertyName'] as String? ?? '',
        coverImage: json['coverImage'] as String?,
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
        totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
        distribution: _parseDistribution(json['distribution']),
        breakdown: json['breakdown'] is Map<String, dynamic>
            ? RatingBreakdown.fromJson(
                json['breakdown'] as Map<String, dynamic>)
            : const RatingBreakdown(),
      );
}

/// Parse distribution map: backend returns `{"5": 8, "4": 4, ...}` (string keys
/// per JSON spec). Convert to `Map<int, int>` for easier UI lookup.
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

/// Owner-level rating summary — backend computes weighted avg across all of
/// the owner's properties in the period. Prefer this over client-side
/// aggregation from `propertyRatings`.
class RatingSummary {
  final double avgRating;
  final int totalReviews;
  final int totalProperties; // count of properties with reviews (not total)
  final Map<int, int> distribution;
  final RatingBreakdown breakdown;

  const RatingSummary({
    this.avgRating = 0,
    this.totalReviews = 0,
    this.totalProperties = 0,
    this.distribution = const {},
    this.breakdown = const RatingBreakdown(),
  });

  bool get isEmpty => totalReviews == 0;

  factory RatingSummary.fromJson(Map<String, dynamic> json) => RatingSummary(
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
        totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
        totalProperties: (json['totalProperties'] as num?)?.toInt() ?? 0,
        distribution: _parseDistribution(json['distribution']),
        breakdown: json['breakdown'] is Map<String, dynamic>
            ? RatingBreakdown.fromJson(
                json['breakdown'] as Map<String, dynamic>)
            : const RatingBreakdown(),
      );
}

/// Length of stay distribution (number of nights) — histogram buckets.
class LengthOfStayDistribution {
  final int oneNight;
  final int twoToThree;
  final int fourToSeven;
  final int eightPlus;

  const LengthOfStayDistribution({
    this.oneNight = 0,
    this.twoToThree = 0,
    this.fourToSeven = 0,
    this.eightPlus = 0,
  });

  factory LengthOfStayDistribution.fromJson(Map<String, dynamic> json) =>
      LengthOfStayDistribution(
        oneNight: (json['oneNight'] as num?)?.toInt() ?? 0,
        twoToThree: (json['twoToThree'] as num?)?.toInt() ?? 0,
        fourToSeven: (json['fourToSeven'] as num?)?.toInt() ?? 0,
        eightPlus: (json['eightPlus'] as num?)?.toInt() ?? 0,
      );

  int get total => oneNight + twoToThree + fourToSeven + eightPlus;

  List<({String label, int count})> get buckets => [
        (label: '1 đêm', count: oneNight),
        (label: '2-3 đêm', count: twoToThree),
        (label: '4-7 đêm', count: fourToSeven),
        (label: '8+ đêm', count: eightPlus),
      ];
}

/// Occupancy by day of week (Mon-Sun). Value 0..1.
class DayOfWeekOccupancy {
  /// Index 0 = T2 (Monday), 6 = CN (Sunday).
  final List<double> values;

  const DayOfWeekOccupancy({this.values = const [0, 0, 0, 0, 0, 0, 0]});

  factory DayOfWeekOccupancy.fromJson(Map<String, dynamic> json) {
    final raw = (json['values'] as List?)?.cast<num>() ?? const [];
    final padded = List<double>.filled(7, 0);
    for (var i = 0; i < raw.length && i < 7; i++) {
      padded[i] = raw[i].toDouble();
    }
    return DayOfWeekOccupancy(values: padded);
  }

  bool get isEmpty => values.every((v) => v == 0);
}

/// One customer review.
class CustomerReview {
  final String id;
  final String propertyId;
  final String propertyName;
  final String customerName;
  final String? customerAvatar;
  final double rating; // 1..5
  final String comment;
  final DateTime createdAt;
  final List<String> photos;

  const CustomerReview({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.customerName,
    this.customerAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.photos = const [],
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) => CustomerReview(
        id: json['id'] as String,
        propertyId: json['propertyId'] as String? ?? '',
        propertyName: json['propertyName'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        customerAvatar: json['customerAvatar'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        photos: (json['photos'] as List?)?.cast<String>() ?? const [],
      );
}

/// Comparison with previous period (% change).
class PreviousPeriodComparison {
  final int revenue;
  final int bookings;
  final double occupancy;
  final int adr;

  const PreviousPeriodComparison({
    this.revenue = 0,
    this.bookings = 0,
    this.occupancy = 0,
    this.adr = 0,
  });

  factory PreviousPeriodComparison.fromJson(Map<String, dynamic> json) =>
      PreviousPeriodComparison(
        revenue: (json['revenue'] as num?)?.toInt() ?? 0,
        bookings: (json['bookings'] as num?)?.toInt() ?? 0,
        occupancy: (json['occupancy'] as num?)?.toDouble() ?? 0,
        adr: (json['adr'] as num?)?.toInt() ?? 0,
      );
}

/// Period filter for report screen.
enum ReportPeriod { today, week, month, year, custom }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
        ReportPeriod.today => 'Hôm nay',
        ReportPeriod.week => 'Tuần này',
        ReportPeriod.month => 'Tháng này',
        ReportPeriod.year => 'Năm nay',
        ReportPeriod.custom => 'Tuỳ chỉnh',
      };

  String get apiValue => switch (this) {
        ReportPeriod.today => 'today',
        ReportPeriod.week => 'week',
        ReportPeriod.month => 'month',
        ReportPeriod.year => 'year',
        ReportPeriod.custom => 'custom',
      };
}

/// Aggregated report data — backend serves via `/reports`. Backend wires all
/// 9 new fields (revenue, adr, revenueByDay, topRooms, previousPeriod,
/// ratingSummary, propertyRatings, recentReviews, lengthOfStay,
/// dayOfWeekOccupancy) — see `api-reviews-reports-frontend-spec.md`.
class ReportData {
  final int totalRooms;
  final int activeRooms;
  final int totalBookings;
  final int thisMonthBookings;
  final int holdCount;
  final int confirmedCount;
  final int cancelledCount;
  final int completedCount;
  final double totalDeposit;
  final double occupancyRate; // 0..100
  final int roomsWithCover;
  final int roomsWithPrice;
  final List<BookingModel> recentBookings;

  /// Actual revenue (not just deposit). VND.
  final int revenue;

  /// ADR — Average Daily Rate (revenue / room-nights sold). VND.
  final int adr;

  /// Daily trend data for line chart.
  final List<RevenuePoint> revenueByDay;

  /// Top 5 rooms by revenue.
  final List<TopRoom> topRooms;

  /// Previous-period comparison.
  final PreviousPeriodComparison previousPeriod;

  /// Per-property aggregate ratings.
  final List<PropertyRating> propertyRatings;

  /// Owner-level rating summary — backend precomputes weighted avg.
  /// When `null` (legacy backend) → fallback computes from `propertyRatings`
  /// via the `overall*` getters.
  final RatingSummary? ratingSummary;

  /// Latest reviews (preview).
  final List<CustomerReview> recentReviews;

  /// Length-of-stay histogram by bucket.
  final LengthOfStayDistribution lengthOfStay;

  /// Occupancy by day of week (Mon-Sun).
  final DayOfWeekOccupancy dayOfWeekOccupancy;

  const ReportData({
    this.totalRooms = 0,
    this.activeRooms = 0,
    this.totalBookings = 0,
    this.thisMonthBookings = 0,
    this.holdCount = 0,
    this.confirmedCount = 0,
    this.cancelledCount = 0,
    this.completedCount = 0,
    this.totalDeposit = 0,
    this.occupancyRate = 0,
    this.roomsWithCover = 0,
    this.roomsWithPrice = 0,
    this.recentBookings = const [],
    this.revenue = 0,
    this.adr = 0,
    this.revenueByDay = const [],
    this.topRooms = const [],
    this.previousPeriod = const PreviousPeriodComparison(),
    this.propertyRatings = const [],
    this.ratingSummary,
    this.recentReviews = const [],
    this.lengthOfStay = const LengthOfStayDistribution(),
    this.dayOfWeekOccupancy = const DayOfWeekOccupancy(),
  });

  /// Overall avg rating across all properties (weighted by review count).
  /// Prefer `ratingSummary` from backend, fall back to computing from
  /// `propertyRatings` for legacy backend.
  double get overallAvgRating {
    if (ratingSummary != null) return ratingSummary!.avgRating;
    if (propertyRatings.isEmpty) return 0;
    var sumRating = 0.0;
    var sumReviews = 0;
    for (final p in propertyRatings) {
      sumRating += p.avgRating * p.totalReviews;
      sumReviews += p.totalReviews;
    }
    return sumReviews == 0 ? 0 : sumRating / sumReviews;
  }

  int get overallTotalReviews {
    if (ratingSummary != null) return ratingSummary!.totalReviews;
    return propertyRatings.fold(0, (sum, p) => sum + p.totalReviews);
  }

  /// Aggregate distribution across all reviews (sum per star).
  Map<int, int> get overallDistribution {
    if (ratingSummary != null) return ratingSummary!.distribution;
    final result = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final p in propertyRatings) {
      p.distribution.forEach((star, count) {
        result[star] = (result[star] ?? 0) + count;
      });
    }
    return result;
  }

  /// 6-criteria breakdown — weighted average by each property's review count.
  RatingBreakdown get overallBreakdown {
    if (ratingSummary != null) return ratingSummary!.breakdown;
    if (propertyRatings.isEmpty) return const RatingBreakdown();
    var sumC = 0.0, sumL = 0.0, sumA = 0.0, sumS = 0.0, sumV = 0.0, sumAc = 0.0;
    var sumW = 0;
    for (final p in propertyRatings) {
      if (p.breakdown.isEmpty) continue;
      final w = p.totalReviews;
      sumC += p.breakdown.cleanliness * w;
      sumL += p.breakdown.location * w;
      sumA += p.breakdown.amenities * w;
      sumS += p.breakdown.service * w;
      sumV += p.breakdown.value * w;
      sumAc += p.breakdown.accuracy * w;
      sumW += w;
    }
    if (sumW == 0) return const RatingBreakdown();
    return RatingBreakdown(
      cleanliness: sumC / sumW,
      location: sumL / sumW,
      amenities: sumA / sumW,
      service: sumS / sumW,
      value: sumV / sumW,
      accuracy: sumAc / sumW,
    );
  }

  factory ReportData.fromJson(Map<String, dynamic> json) => ReportData(
        totalRooms: json['totalRooms'] ?? 0,
        activeRooms: json['activeRooms'] ?? 0,
        totalBookings: json['totalBookings'] ?? 0,
        thisMonthBookings: json['thisMonthBookings'] ?? 0,
        holdCount: json['holdCount'] ?? 0,
        confirmedCount: json['confirmedCount'] ?? 0,
        cancelledCount: json['cancelledCount'] ?? 0,
        completedCount: json['completedCount'] ?? 0,
        totalDeposit: (json['totalDeposit'] as num?)?.toDouble() ?? 0,
        occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0,
        roomsWithCover: json['roomsWithCover'] ?? 0,
        roomsWithPrice: json['roomsWithPrice'] ?? 0,
        recentBookings:
            (json['recentBookingsParsed'] as List<BookingModel>?) ?? const [],
        revenue: (json['revenue'] as num?)?.toInt() ?? 0,
        adr: (json['adr'] as num?)?.toInt() ?? 0,
        revenueByDay: (json['revenueByDay'] as List?)
                ?.map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        topRooms: (json['topRooms'] as List?)
                ?.map((e) => TopRoom.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        previousPeriod: json['previousPeriod'] is Map<String, dynamic>
            ? PreviousPeriodComparison.fromJson(
                json['previousPeriod'] as Map<String, dynamic>)
            : const PreviousPeriodComparison(),
        propertyRatings: (json['propertyRatings'] as List?)
                ?.map((e) => PropertyRating.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        ratingSummary: json['ratingSummary'] is Map<String, dynamic>
            ? RatingSummary.fromJson(
                json['ratingSummary'] as Map<String, dynamic>)
            : null,
        recentReviews: (json['recentReviews'] as List?)
                ?.map((e) => CustomerReview.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        lengthOfStay: json['lengthOfStay'] is Map<String, dynamic>
            ? LengthOfStayDistribution.fromJson(
                json['lengthOfStay'] as Map<String, dynamic>)
            : const LengthOfStayDistribution(),
        dayOfWeekOccupancy: json['dayOfWeekOccupancy'] is Map<String, dynamic>
            ? DayOfWeekOccupancy.fromJson(
                json['dayOfWeekOccupancy'] as Map<String, dynamic>)
            : const DayOfWeekOccupancy(),
      );
}
