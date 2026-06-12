import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/profile_settings_controller.dart';
import '../data/models/data_export_request.dart';

class DataRequestScreen extends ConsumerWidget {
  const DataRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportsAsync = ref.watch(dataExportListProvider);
    final colors = context.colors;
    final isRequesting = ref.watch(dataExportActionsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu dữ liệu cá nhân')),
      body: exportsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(dataExportListProvider),
        ),
        data: (exports) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dataExportListProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Text(
                  'Yêu cầu bản sao dữ liệu cá nhân: tài khoản, booking, '
                  'giao dịch. File sẽ sẵn sàng khi BE xử lý xong.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed:
                    isRequesting ? null : () => _requestExport(context, ref),
                icon: isRequesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
                label: const Text('Yêu cầu tải dữ liệu'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Lịch sử yêu cầu',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (exports.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.folder_open_outlined,
                  message: 'Chưa có yêu cầu xuất dữ liệu',
                )
              else
                ...exports.map((e) => _RequestHistoryTile(export: e)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestExport(BuildContext context, WidgetRef ref) async {
    final (ok, msg) =
        await ref.read(dataExportActionsProvider.notifier).requestExport();
    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.success(context, msg);
    } else {
      AppSnackBar.error(context, msg);
    }
  }
}

class _RequestHistoryTile extends StatelessWidget {
  final DataExportRequest export;

  const _RequestHistoryTile({required this.export});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = export.isReady;
    final time = export.requestedAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(export.requestedAt!.toLocal())
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: ListTile(
        title: Text(export.displayFile),
        subtitle: Text('${export.statusLabel} · $time'),
        trailing: Icon(
          isDone ? Icons.check_circle_outline : Icons.timelapse_outlined,
          color: isDone ? colors.success : colors.warning,
        ),
        onTap: isDone && export.downloadUrl != null
            ? () => _openDownload(export.downloadUrl!)
            : null,
      ),
    );
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
