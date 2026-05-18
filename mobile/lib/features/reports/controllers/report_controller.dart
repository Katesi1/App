import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/report_repository.dart';
import '../data/report_models.dart';

// Re-export so old callers can still import from controller.
export '../data/report_models.dart';

/// Report filter params. `period` is an enum (today/week/month/year/custom).
/// When `custom` → `from`/`to` are required. Backward-compat with `month/year`.
class ReportParams {
  final ReportPeriod period;
  final DateTime? from;
  final DateTime? to;

  /// Legacy: only used when `period == ReportPeriod.month` calls old backend.
  final int? month;
  final int? year;

  const ReportParams({
    this.period = ReportPeriod.month,
    this.from,
    this.to,
    this.month,
    this.year,
  });

  ReportParams copyWith({
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) =>
      ReportParams(
        period: period ?? this.period,
        from: from ?? this.from,
        to: to ?? this.to,
        month: month ?? this.month,
        year: year ?? this.year,
      );

  @override
  bool operator ==(Object other) =>
      other is ReportParams &&
      period == other.period &&
      from == other.from &&
      to == other.to &&
      month == other.month &&
      year == other.year;

  @override
  int get hashCode => Object.hash(period, from, to, month, year);
}

final reportRepositoryProvider =
    Provider<ReportRepository>((ref) => ReportRepository());

/// Period filter state (UI controlled). Default = current month.
final selectedReportParamsProvider =
    StateProvider<ReportParams>((ref) => const ReportParams());

/// Report provider. Backend supports `period/from/to` (defaults to `month`
/// if not passed). Custom period requires both `from` and `to`.
/// Legacy `month/year` only used when explicit (rare).
final reportDataProvider = FutureProvider.autoDispose
    .family<ReportData, ReportParams?>((ref, params) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 2), link.close);
  final repo = ref.read(reportRepositoryProvider);

  final p = params ?? const ReportParams();
  // Custom period requires both from/to — if missing, fall back to default
  // month to avoid 400 request when user just opens the picker.
  final useCustom = p.period == ReportPeriod.custom &&
      p.from != null &&
      p.to != null;

  final result = await repo.getReport(
    period: useCustom ? 'custom' : p.period.apiValue,
    from: useCustom ? p.from : null,
    to: useCustom ? p.to : null,
    month: p.month,
    year: p.year,
  );
  if (result.success) return ReportData.fromJson(result.data!);
  throw Exception(result.message);
});
