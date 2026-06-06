import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/abuse_report_controller.dart';
import '../data/models/abuse_report.dart';

class AbuseReportsScreen extends ConsumerWidget {
  const AbuseReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filter = ref.watch(abuseReportFilterProvider);
    final listAsync = ref.watch(filteredAbuseReportsProvider);
    final pendingCount =
        ref.watch(pendingAbuseReportCountProvider).valueOrNull ?? 0;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.jade900, AppColors.jade500],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -50,
                  top: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.jade300.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold500.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Báo cáo vi phạm',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$pendingCount báo cáo cần xử lý',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _FilterTabs(
            current: filter,
            onChanged: (f) =>
                ref.read(abuseReportFilterProvider.notifier).state = f,
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có báo cáo',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: colors.brand,
                  onRefresh: () async => ref.invalidate(abuseReportsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return const _SummaryCard();
                      }
                      final report = list[i - 1];
                      return _ReportTile(
                        report: report,
                        onTap: () =>
                            context.push('/admin/abuse-reports/${report.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final AbuseReportFilter current;
  final ValueChanged<AbuseReportFilter> onChanged;

  const _FilterTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const tabs = [
      (AbuseReportFilter.pending, 'Chờ xử lý'),
      (AbuseReportFilter.all, 'Tất cả'),
      (AbuseReportFilter.resolved, 'Đã xử lý'),
      (AbuseReportFilter.dismissed, 'Bỏ qua'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: tabs.map((t) {
          final active = current == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => onChanged(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? colors.brand : colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: active ? colors.brand : colors.borderDefault,
                  ),
                ),
                child: Text(
                  t.$2,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? colors.textOnPrimary : colors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Text(
        'Chạm vào từng báo cáo để xem chi tiết và xử lý. '
        'Hành động moderation sẽ được ghi vào lịch sử hệ thống.',
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final AbuseReport report;
  final VoidCallback onTap;

  const _ReportTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isHigh = report.level == AbuseReportLevel.high;

    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${report.reporterName} · ${report.category.label}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _badge(
                          'Mức: ${report.level.label}',
                          isHigh ? colors.error : colors.warning,
                        ),
                        const SizedBox(width: 6),
                        _badge(
                          report.status.label,
                          colors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
