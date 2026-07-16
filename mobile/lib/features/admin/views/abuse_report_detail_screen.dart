import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/abuse_report_controller.dart';
import '../data/models/abuse_report.dart';

class AbuseReportDetailScreen extends ConsumerWidget {
  final String reportId;

  const AbuseReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(abuseReportDetailProvider(reportId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'Chi tiết báo cáo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: colors.brand,
        onRefresh: () async =>
            ref.invalidate(abuseReportDetailProvider(reportId)),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => RefreshableMessage(
            child: Center(child: Text('Lỗi: $e')),
          ),
          data: (report) {
            if (report == null) {
              return const RefreshableMessage(
                child: Center(child: Text('Không tìm thấy báo cáo.')),
              );
            }
            return _Content(report: report);
          },
        ),
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  final AbuseReport report;
  const _Content({required this.report});

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  final _resolutionCtrl = TextEditingController();
  bool _hideContent = false;
  bool _banUser = false;

  @override
  void dispose() {
    _resolutionCtrl.dispose();
    super.dispose();
  }

  String get _adminName => ref.read(currentUserProvider)?.name ?? 'Admin';

  Future<void> _investigate() async {
    final ok = await ref
        .read(abuseReportActionsProvider.notifier)
        .investigate(widget.report.id, adminName: _adminName);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã chuyển sang điều tra');
    }
  }

  Future<void> _dismiss() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bỏ qua báo cáo?'),
        content: const Text(
          'Báo cáo sẽ được đánh dấu không hợp lệ. '
          'Hành động này được ghi vào nhật ký hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bỏ qua'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await ref
        .read(abuseReportActionsProvider.notifier)
        .dismiss(widget.report.id, adminName: _adminName);
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Đã bỏ qua báo cáo');
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _resolve() async {
    final resolution = _resolutionCtrl.text.trim();
    if (resolution.length < 5) {
      AppSnackBar.info(context, 'Ghi chú xử lý tối thiểu 5 ký tự');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xử lý?'),
        content: Text(
          'Ghi chú: $resolution'
          '${_hideContent ? '\n• Ẩn nội dung' : ''}'
          '${_banUser ? '\n• Khóa user' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await ref.read(abuseReportActionsProvider.notifier).resolve(
          widget.report.id,
          adminName: _adminName,
          resolution: resolution,
          hideContent: _hideContent,
          banUser: _banUser,
        );
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Đã xử lý báo cáo');
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = widget.report;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final isActionable = r.status.isActionable;
    final isHigh = r.level == AbuseReportLevel.high;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _StatusBanner(report: r),
              const SizedBox(height: AppSpacing.md),
              _InfoCard(
                title: 'Nội dung báo cáo',
                children: [
                  Text(
                    r.title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.description,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoCard(
                title: 'Thông tin',
                children: [
                  _row('Người báo cáo', '${r.reporterName} (${r.reporterId})'),
                  _row('Danh mục', r.category.label),
                  _row(
                    'Mức độ',
                    r.level.label,
                    valueColor: isHigh ? colors.error : colors.warning,
                  ),
                  _row('Đối tượng', '${r.targetType.label}: ${r.targetLabel}'),
                  _row('Mã đối tượng', r.targetId),
                  _row('Thời gian', dateFmt.format(r.createdAt)),
                  if (r.handledBy != null) _row('Xử lý bởi', r.handledBy!),
                  if (r.handledAt != null)
                    _row('Xử lý lúc', dateFmt.format(r.handledAt!)),
                  if (r.resolution != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Kết quả: ${r.resolution}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              if (isActionable) ...[
                const SizedBox(height: AppSpacing.sm),
                _InfoCard(
                  title: 'Ghi chú xử lý',
                  children: [
                    TextField(
                      controller: _resolutionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Mô tả hành động đã thực hiện (≥5 ký tự)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (r.targetType == AbuseTargetType.property ||
                        r.targetType == AbuseTargetType.review) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ẩn nội dung vi phạm'),
                        value: _hideContent,
                        onChanged: (v) =>
                            setState(() => _hideContent = v ?? false),
                      ),
                    ],
                    if (r.targetType == AbuseTargetType.user) ...[
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Khóa tài khoản vi phạm'),
                        value: _banUser,
                        onChanged: (v) => setState(() => _banUser = v ?? false),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        if (isActionable)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  if (r.status == AbuseReportStatus.pending)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _investigate,
                        child: const Text('Chuyển điều tra'),
                      ),
                    ),
                  if (r.status == AbuseReportStatus.pending)
                    const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _dismiss,
                          child: const Text('Bỏ qua'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _resolve,
                          child: const Text('Xử lý xong'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final AbuseReport report;
  const _StatusBanner({required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg, icon) = switch (report.status) {
      AbuseReportStatus.pending => (
          colors.warning.withValues(alpha: 0.12),
          colors.warning,
          Icons.pending_outlined,
        ),
      AbuseReportStatus.investigating => (
          colors.info.withValues(alpha: 0.12),
          colors.info,
          Icons.search_rounded,
        ),
      AbuseReportStatus.resolved => (
          colors.success.withValues(alpha: 0.12),
          colors.success,
          Icons.check_circle_outline,
        ),
      AbuseReportStatus.dismissed => (
          colors.textSecondary.withValues(alpha: 0.12),
          colors.textSecondary,
          Icons.block_outlined,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Text(
            report.status.label,
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
