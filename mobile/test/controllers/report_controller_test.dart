import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/repositories/report_repository.dart';
import 'package:mobile/features/reports/controllers/report_controller.dart';

// ── Fake repository ───────────────────────────────────────────────────────────
class FakeReportRepository extends ReportRepository {
  Map<String, dynamic>? fakeData;
  String? errorMessage;

  @override
  Future<ApiResponse<Map<String, dynamic>>> getReport({
    String? period,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    return ApiResponse(
      success: true,
      data: fakeData ?? {},
      message: '',
    );
  }
}

void main() {
  group('selectedReportParamsProvider', () {
    test('initial value is default ReportParams (month period)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final params = container.read(selectedReportParamsProvider);
      expect(params.period, ReportPeriod.month);
    });

    test('can be updated to different period', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedReportParamsProvider.notifier).state =
          const ReportParams(period: ReportPeriod.year);
      expect(
          container.read(selectedReportParamsProvider).period, ReportPeriod.year);
    });

    test('can be updated to custom period with from/to', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final params = ReportParams(
        period: ReportPeriod.custom,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      );
      container.read(selectedReportParamsProvider.notifier).state = params;
      final saved = container.read(selectedReportParamsProvider);
      expect(saved.period, ReportPeriod.custom);
      expect(saved.from, DateTime(2026, 1, 1));
      expect(saved.to, DateTime(2026, 1, 31));
    });
  });

  group('reportDataProvider', () {
    test('returns ReportData on success', () async {
      final fakeRepo = FakeReportRepository();
      fakeRepo.fakeData = {
        'totalRooms': 5,
        'totalBookings': 10,
        'holdCount': 2,
        'confirmedCount': 8,
      };
      final container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(reportDataProvider(null).future);
      expect(result.totalRooms, 5);
      expect(result.totalBookings, 10);
      expect(result.holdCount, 2);
      expect(result.confirmedCount, 8);
    });

    test('throws Exception on failure', () async {
      final fakeRepo = FakeReportRepository();
      fakeRepo.errorMessage = 'Lỗi kết nối';
      final container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(reportDataProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('passes period param to repository', () async {
      String? capturedPeriod;
      final fakeRepo = _CapturingFakeRepo((period) => capturedPeriod = period);
      final container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      const params = ReportParams(period: ReportPeriod.week);
      await container.read(reportDataProvider(params).future);
      expect(capturedPeriod, 'week');
    });

    test('uses custom period when from/to are set', () async {
      String? capturedPeriod;
      DateTime? capturedFrom;
      final fakeRepo = _CapturingFakeRepo(
        (period) => capturedPeriod = period,
        onFrom: (from) => capturedFrom = from,
      );
      final container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final params = ReportParams(
        period: ReportPeriod.custom,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      );
      await container.read(reportDataProvider(params).future);
      expect(capturedPeriod, 'custom');
      expect(capturedFrom, DateTime(2026, 1, 1));
    });

    test('sends apiValue when custom period missing from/to', () async {
      String? capturedPeriod;
      final fakeRepo =
          _CapturingFakeRepo((period) => capturedPeriod = period);
      final container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // custom without from/to → useCustom=false → period = p.period.apiValue = 'custom'
      const params = ReportParams(period: ReportPeriod.custom);
      await container.read(reportDataProvider(params).future);
      expect(capturedPeriod, 'custom');
    });

    test('null params uses month default', () async {
      String? capturedPeriod;
      final fakeRepo =
          _CapturingFakeRepo((period) => capturedPeriod = period);
      final container = ProviderContainer(
        overrides: [
          reportRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // null params → ReportParams() → period = ReportPeriod.month → 'month'
      await container.read(reportDataProvider(null).future);
      expect(capturedPeriod, 'month');
    });
  });
}

// Helper fake that captures repo call params
class _CapturingFakeRepo extends ReportRepository {
  final void Function(String?) onPeriod;
  final void Function(DateTime?)? onFrom;

  _CapturingFakeRepo(this.onPeriod, {this.onFrom});

  @override
  Future<ApiResponse<Map<String, dynamic>>> getReport({
    String? period,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) async {
    onPeriod(period);
    onFrom?.call(from);
    return ApiResponse(success: true, data: {}, message: '');
  }
}
