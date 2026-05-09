import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/report_repository.dart';
import '../data/report_models.dart';

// Re-export để các caller cũ vẫn import từ controller được.
export '../data/report_models.dart';

/// Filter params cho report. `period` là enum (today/week/month/year/custom).
/// Khi `custom` → `from`/`to` bắt buộc. Backward-compat với `month/year`.
class ReportParams {
  final ReportPeriod period;
  final DateTime? from;
  final DateTime? to;

  /// Legacy: chỉ dùng khi `period == ReportPeriod.month` mà gọi backend cũ.
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

/// State của period filter (UI controlled). Default = tháng hiện tại.
final selectedReportParamsProvider =
    StateProvider<ReportParams>((ref) => const ReportParams());

/// Provider lấy report. Backend đã support `period/from/to` (mặc định
/// `month` nếu không truyền). Custom period bắt buộc cả `from` lẫn `to`.
/// Legacy `month/year` chỉ dùng khi explicit (rare).
final reportDataProvider = FutureProvider.autoDispose
    .family<ReportData, ReportParams?>((ref, params) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 2), link.close);
  final repo = ref.read(reportRepositoryProvider);

  final p = params ?? const ReportParams();
  // Custom period bắt buộc đủ from/to — nếu thiếu thì rơi về month mặc định
  // để tránh request 400 ngay lúc user mới mở picker.
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
