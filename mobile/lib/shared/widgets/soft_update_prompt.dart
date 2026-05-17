import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/app_version_service.dart';

/// Hiện dialog cập nhật theo mức độ:
/// - [AppVersionStatus.softUpdate]: dismissible, có nút "Để sau"
/// - [AppVersionStatus.forceUpdate]: KHÔNG dismissible, chỉ có nút "Cập nhật"
///
/// Trả `true` nếu user bấm Cập nhật + đã mở store URL thành công.
Future<bool> showAppUpdatePrompt(
  BuildContext context, {
  required AppVersionInfo info,
}) async {
  if (info.status == AppVersionStatus.upToDate ||
      info.status == AppVersionStatus.unknown) {
    return false;
  }

  final isForce = info.status == AppVersionStatus.forceUpdate;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !isForce,
    builder: (_) => PopScope(
      canPop: !isForce, // chặn back button khi force-update
      child: AlertDialog(
        title: Text(
          isForce ? 'Bắt buộc cập nhật' : 'Có bản cập nhật mới',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isForce
                  ? 'Phiên bản hiện tại (${info.currentVersion}) không '
                      'còn được hỗ trợ. Vui lòng cập nhật lên phiên bản '
                      '${info.latestVersion ?? "mới nhất"} để tiếp tục dùng app.'
                  : 'Phiên bản mới ${info.latestVersion ?? ""} đã sẵn sàng. '
                      'Bạn nên cập nhật để có trải nghiệm ổn định hơn.',
            ),
            if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Có gì mới:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(info.releaseNotes!),
            ],
          ],
        ),
        actions: [
          if (!isForce)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Để sau'),
            ),
          FilledButton(
            onPressed: () async {
              final url = info.storeUrl;
              if (url != null && url.isNotEmpty) {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
              if (!context.mounted) return;
              if (!isForce) Navigator.of(context).pop(true);
              // Force-update: KHÔNG pop — giữ dialog tới khi user
              // restart app sau khi update.
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Backwards-compat wrapper — gọi từ code cũ chỉ truyền version.
@Deprecated('Use showAppUpdatePrompt with AppVersionInfo instead')
Future<void> showSoftUpdatePrompt(
  BuildContext context, {
  required String latestVersion,
}) =>
    showAppUpdatePrompt(
      context,
      info: AppVersionInfo(
        status: AppVersionStatus.softUpdate,
        currentVersion: '0.0.0',
        latestVersion: latestVersion,
      ),
    );
