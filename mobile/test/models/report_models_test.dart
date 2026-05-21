import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/controllers/report_controller.dart';

void main() {
  // ─── ReportPeriod enum ────────────────────────────────────────────────────
  group('ReportPeriod', () {
    test('label returns correct Vietnamese strings', () {
      expect(ReportPeriod.today.label, 'Hôm nay');
      expect(ReportPeriod.week.label, 'Tuần này');
      expect(ReportPeriod.month.label, 'Tháng này');
      expect(ReportPeriod.year.label, 'Năm nay');
      expect(ReportPeriod.custom.label, 'Tuỳ chỉnh');
    });

    test('apiValue returns correct API strings', () {
      expect(ReportPeriod.today.apiValue, 'today');
      expect(ReportPeriod.week.apiValue, 'week');
      expect(ReportPeriod.month.apiValue, 'month');
      expect(ReportPeriod.year.apiValue, 'year');
      expect(ReportPeriod.custom.apiValue, 'custom');
    });

    test('all 5 values exist', () {
      expect(ReportPeriod.values.length, 5);
    });
  });

  // ─── ReportParams ─────────────────────────────────────────────────────────
  group('ReportParams', () {
    test('default constructor sets period to month', () {
      const params = ReportParams();
      expect(params.period, ReportPeriod.month);
      expect(params.from, isNull);
      expect(params.to, isNull);
      expect(params.month, isNull);
      expect(params.year, isNull);
    });

    test('equality — same values are equal', () {
      final a = ReportParams(
        period: ReportPeriod.week,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 7),
      );
      final b = ReportParams(
        period: ReportPeriod.week,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 7),
      );
      expect(a, equals(b));
    });

    test('equality — different period is not equal', () {
      const a = ReportParams(period: ReportPeriod.month);
      const b = ReportParams(period: ReportPeriod.week);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent for equal objects', () {
      const a = ReportParams(period: ReportPeriod.today, month: 5, year: 2026);
      const b = ReportParams(period: ReportPeriod.today, month: 5, year: 2026);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith changes only specified fields', () {
      const original = ReportParams(
        period: ReportPeriod.month,
        month: 4,
        year: 2026,
      );
      final updated = original.copyWith(period: ReportPeriod.year);
      expect(updated.period, ReportPeriod.year);
      expect(updated.month, 4);
      expect(updated.year, 2026);
    });

    test('copyWith with all fields', () {
      final d1 = DateTime(2026, 1, 1);
      final d2 = DateTime(2026, 1, 31);
      const original = ReportParams();
      final updated = original.copyWith(
        period: ReportPeriod.custom,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
        month: 1,
        year: 2026,
      );
      expect(updated.period, ReportPeriod.custom);
      expect(updated.from, d1);
      expect(updated.to, d2);
      expect(updated.month, 1);
      expect(updated.year, 2026);
    });
  });

  // ─── RatingBreakdown ──────────────────────────────────────────────────────
  group('RatingBreakdown', () {
    test('default constructor has zero scores', () {
      const rb = RatingBreakdown();
      expect(rb.cleanliness, 0);
      expect(rb.location, 0);
      expect(rb.amenities, 0);
      expect(rb.service, 0);
      expect(rb.value, 0);
      expect(rb.accuracy, 0);
    });

    test('isEmpty returns true when all zero', () {
      const rb = RatingBreakdown();
      expect(rb.isEmpty, isTrue);
    });

    test('isEmpty returns false when any non-zero', () {
      const rb = RatingBreakdown(cleanliness: 4.5);
      expect(rb.isEmpty, isFalse);
    });

    test('fromJson parses scores', () {
      final rb = RatingBreakdown.fromJson({
        'cleanliness': 4.8,
        'location': 4.5,
        'amenities': 4.2,
        'service': 4.7,
        'value': 4.0,
        'accuracy': 4.6,
      });
      expect(rb.cleanliness, 4.8);
      expect(rb.location, 4.5);
      expect(rb.amenities, 4.2);
      expect(rb.service, 4.7);
      expect(rb.value, 4.0);
      expect(rb.accuracy, 4.6);
      expect(rb.isEmpty, isFalse);
    });

    test('items returns 6 entries', () {
      const rb = RatingBreakdown(
        cleanliness: 4.5,
        location: 4.0,
        amenities: 3.5,
        service: 4.8,
        value: 4.2,
        accuracy: 4.4,
      );
      expect(rb.items.length, 6);
      expect(rb.items[0].label, 'Sạch sẽ');
      expect(rb.items[0].score, 4.5);
      expect(rb.items[1].label, 'Vị trí');
    });
  });

  // ─── LengthOfStayDistribution ─────────────────────────────────────────────
  group('LengthOfStayDistribution', () {
    test('total returns sum of all buckets', () {
      const dist = LengthOfStayDistribution(
        oneNight: 5,
        twoToThree: 10,
        fourToSeven: 8,
        eightPlus: 2,
      );
      expect(dist.total, 25);
    });

    test('fromJson parses all buckets', () {
      final dist = LengthOfStayDistribution.fromJson({
        'oneNight': 5,
        'twoToThree': 10,
        'fourToSeven': 8,
        'eightPlus': 2,
      });
      expect(dist.oneNight, 5);
      expect(dist.twoToThree, 10);
      expect(dist.fourToSeven, 8);
      expect(dist.eightPlus, 2);
      expect(dist.total, 25);
    });

    test('buckets returns 4 entries with correct labels', () {
      const dist = LengthOfStayDistribution(oneNight: 3);
      final buckets = dist.buckets;
      expect(buckets.length, 4);
      expect(buckets[0].label, '1 đêm');
      expect(buckets[0].count, 3);
      expect(buckets[1].label, '2-3 đêm');
    });
  });

  // ─── DayOfWeekOccupancy ───────────────────────────────────────────────────
  group('DayOfWeekOccupancy', () {
    test('default has 7 zero values', () {
      const occ = DayOfWeekOccupancy();
      expect(occ.values.length, 7);
      expect(occ.isEmpty, isTrue);
    });

    test('fromJson parses 7 values', () {
      final occ = DayOfWeekOccupancy.fromJson({
        'values': [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.4],
      });
      expect(occ.values.length, 7);
      expect(occ.values[0], 0.5);
      expect(occ.values[6], 0.4);
      expect(occ.isEmpty, isFalse);
    });

    test('fromJson pads to 7 if fewer values', () {
      final occ = DayOfWeekOccupancy.fromJson({
        'values': [0.5, 0.6],
      });
      expect(occ.values.length, 7);
      expect(occ.values[0], 0.5);
      expect(occ.values[2], 0.0);
    });

    test('fromJson handles missing values key', () {
      final occ = DayOfWeekOccupancy.fromJson({});
      expect(occ.values.length, 7);
      expect(occ.isEmpty, isTrue);
    });
  });

  // ─── RevenuePoint ─────────────────────────────────────────────────────────
  group('RevenuePoint', () {
    test('fromJson parses correctly', () {
      final pt = RevenuePoint.fromJson({
        'date': '2026-05-01',
        'revenue': 5000000,
        'bookings': 3,
        'occupancy': 0.75,
      });
      expect(pt.date, DateTime(2026, 5, 1));
      expect(pt.revenue, 5000000);
      expect(pt.bookings, 3);
      expect(pt.occupancy, 0.75);
    });
  });

  // ─── PreviousPeriodComparison ─────────────────────────────────────────────
  group('PreviousPeriodComparison', () {
    test('default constructor zeros', () {
      const ppc = PreviousPeriodComparison();
      expect(ppc.revenue, 0);
      expect(ppc.bookings, 0);
      expect(ppc.occupancy, 0);
      expect(ppc.adr, 0);
    });

    test('fromJson parses all fields', () {
      final ppc = PreviousPeriodComparison.fromJson({
        'revenue': 10,
        'bookings': -5,
        'occupancy': 2.5,
        'adr': 8,
      });
      expect(ppc.revenue, 10);
      expect(ppc.bookings, -5);
      expect(ppc.occupancy, 2.5);
      expect(ppc.adr, 8);
    });
  });

  // ─── RatingSummary ────────────────────────────────────────────────────────
  group('RatingSummary', () {
    test('isEmpty when totalReviews == 0', () {
      const rs = RatingSummary();
      expect(rs.isEmpty, isTrue);
    });

    test('not isEmpty when totalReviews > 0', () {
      const rs = RatingSummary(totalReviews: 5);
      expect(rs.isEmpty, isFalse);
    });

    test('fromJson parses correctly', () {
      final rs = RatingSummary.fromJson({
        'avgRating': 4.2,
        'totalReviews': 50,
        'totalProperties': 3,
        'distribution': {'5': 20, '4': 15, '3': 10, '2': 3, '1': 2},
      });
      expect(rs.avgRating, 4.2);
      expect(rs.totalReviews, 50);
      expect(rs.totalProperties, 3);
      expect(rs.distribution[5], 20);
      expect(rs.distribution[1], 2);
    });
  });

  // ─── ReportData computed getters ──────────────────────────────────────────
  group('ReportData', () {
    test('fromJson handles empty JSON', () {
      final rd = ReportData.fromJson({});
      expect(rd.totalRooms, 0);
      expect(rd.recentBookings, isEmpty);
      expect(rd.revenueByDay, isEmpty);
      expect(rd.topRooms, isEmpty);
    });

    test('overallAvgRating uses ratingSummary when present', () {
      final rd = ReportData(
        ratingSummary: const RatingSummary(avgRating: 4.5, totalReviews: 10),
        propertyRatings: const [
          PropertyRating(
            propertyId: '1',
            propertyName: 'Test',
            avgRating: 3.0,
            totalReviews: 5,
          ),
        ],
      );
      expect(rd.overallAvgRating, 4.5);
    });

    test('overallAvgRating falls back to propertyRatings when no ratingSummary',
        () {
      final rd = ReportData(
        propertyRatings: [
          const PropertyRating(
            propertyId: '1',
            propertyName: 'A',
            avgRating: 4.0,
            totalReviews: 10,
          ),
          const PropertyRating(
            propertyId: '2',
            propertyName: 'B',
            avgRating: 5.0,
            totalReviews: 10,
          ),
        ],
      );
      expect(rd.overallAvgRating, 4.5);
    });

    test('overallAvgRating is 0 when no ratings', () {
      const rd = ReportData();
      expect(rd.overallAvgRating, 0);
    });

    test('overallTotalReviews uses ratingSummary', () {
      final rd = ReportData(
        ratingSummary: const RatingSummary(avgRating: 4.0, totalReviews: 100),
      );
      expect(rd.overallTotalReviews, 100);
    });

    test('overallTotalReviews fallback sums propertyRatings', () {
      final rd = ReportData(
        propertyRatings: [
          const PropertyRating(
            propertyId: '1',
            propertyName: 'A',
            avgRating: 4.0,
            totalReviews: 10,
          ),
          const PropertyRating(
            propertyId: '2',
            propertyName: 'B',
            avgRating: 4.5,
            totalReviews: 20,
          ),
        ],
      );
      expect(rd.overallTotalReviews, 30);
    });

    test('overallDistribution uses ratingSummary when present', () {
      final rd = ReportData(
        ratingSummary: RatingSummary(
          avgRating: 4.0,
          totalReviews: 10,
          distribution: const {5: 5, 4: 3, 3: 2},
        ),
      );
      expect(rd.overallDistribution[5], 5);
    });
  });
}
