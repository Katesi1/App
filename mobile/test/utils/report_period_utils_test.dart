import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/controllers/report_controller.dart';
import 'package:mobile/features/reports/utils/report_period_utils.dart';

void main() {
  group('ReportPeriodUtils', () {
    test('formatRange formats dd/MM/yyyy', () {
      expect(
        ReportPeriodUtils.formatRange(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 30),
        ),
        '01/06/2026 – 30/06/2026',
      );
    });

    test('headline uses custom range when from/to set', () {
      const params = ReportParams(
        period: ReportPeriod.custom,
        from: null,
        to: null,
      );
      expect(ReportPeriodUtils.headline(params), 'tuỳ chỉnh');

      final withRange = params.copyWith(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 15),
      );
      expect(
        ReportPeriodUtils.headline(withRange),
        '01/01/2026 – 15/01/2026',
      );
    });

    test('paramsNeedCustomRange detects missing dates', () {
      expect(
        ReportPeriodUtils.paramsNeedCustomRange(
          const ReportParams(period: ReportPeriod.custom),
        ),
        isTrue,
      );
      expect(
        ReportPeriodUtils.paramsNeedCustomRange(
          ReportParams(
            period: ReportPeriod.custom,
            from: null,
            to: DateTime(2026, 1, 1),
          ),
        ),
        isTrue,
      );
      expect(
        ReportPeriodUtils.paramsNeedCustomRange(
          ReportParams(
            period: ReportPeriod.custom,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 1, 31),
          ),
        ),
        isFalse,
      );
      expect(
        ReportPeriodUtils.paramsNeedCustomRange(
          const ReportParams(period: ReportPeriod.month),
        ),
        isFalse,
      );
    });
  });
}
