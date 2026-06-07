import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/account_controller.dart';
import '../data/models/account_models.dart';

/// Yêu cầu xuất dữ liệu cá nhân — GDPR (`POST/GET /users/me/data-export`).
class DataRequestScreen extends ConsumerStatefulWidget {
  const DataRequestScreen({super.key});

  @override
  ConsumerState<DataRequestScreen> createState() => _DataRequestScreenState();
}

class _DataRequestScreenState extends ConsumerState<DataRequestScreen> {
  bool _requesting = false;

  Future<void> _request() async {
    setState(() => _requesting = true);
    final result =
        await ref.read(accountRepositoryProvider).requestDataExport();
    if (!mounted) return;
    setState(() => _requesting = false);
    if (result.success) {
      ref.invalidate(dataExportsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Đã gửi yêu cầu. Chúng tôi sẽ chuẩn bị dữ liệu và thông báo khi sẵn sàng.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _download(DataExportRequest req) async {
    final url = req.downloadUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exportsAsync = ref.watch(dataExportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu dữ liệu cá nhân')),
      body: RefreshIndicator(
        color: colors.brand,
        onRefresh: () async => ref.invalidate(dataExportsProvider),
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
                'Bạn có thể yêu cầu bản sao dữ liệu cá nhân, bao gồm: '
                'thông tin tài khoản, lịch sử booking và lịch sử giao dịch.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _requesting ? null : _request,
              icon: _requesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(_requesting ? 'Đang gửi...' : 'Yêu cầu tải dữ liệu'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Lịch sử yêu cầu gần đây',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            exportsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingWidget(),
              ),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(dataExportsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'Chưa có yêu cầu nào.',
                    style: TextStyle(color: colors.textTertiary),
                  );
                }
                return Column(
                  children: list
                      .map((r) => _RequestTile(req: r, onDownload: _download))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final DataExportRequest req;
  final ValueChanged<DataExportRequest> onDownload;

  const _RequestTile({required this.req, required this.onDownload});

  static String _two(int n) => n.toString().padLeft(2, '0');
  String _fmt(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year} ${_two(l.hour)}:${_two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = switch (req.status) {
      'ready' => colors.success,
      'expired' => colors.error,
      _ => colors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: ListTile(
        title: Text(
          req.isReady ? 'Bản dữ liệu sẵn sàng tải' : req.statusLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [req.statusLabel, _fmt(req.requestedAt)]
              .where((s) => s.isNotEmpty)
              .join(' · '),
        ),
        trailing: req.isReady
            ? IconButton(
                icon: Icon(Icons.download_rounded, color: colors.brand),
                onPressed: () => onDownload(req),
              )
            : Icon(
                req.status == 'expired'
                    ? Icons.error_outline
                    : Icons.timelapse_outlined,
                color: statusColor,
              ),
      ),
    );
  }
}
