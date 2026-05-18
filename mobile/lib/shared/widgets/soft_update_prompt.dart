import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/app_version_service.dart';

/// Show the update dialog based on severity:
/// - [AppVersionStatus.softUpdate]: dismissible, with a "Later" button
/// - [AppVersionStatus.forceUpdate]: NOT dismissible, only an "Update" button
///
/// Returns `true` if the user tapped Update and the store URL opened successfully.
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
      canPop: !isForce, // block back button on force-update
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
              // Force-update: do NOT pop — keep the dialog open until the
              // user restarts the app after updating.
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Backwards-compat wrapper — called from old code that only passes a version.
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
