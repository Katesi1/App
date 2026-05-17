import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class DataRequestScreen extends StatelessWidget {
  const DataRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu dữ liệu cá nhân')),
      body: ListView(
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi yêu cầu dữ liệu')),
              );
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Yêu cầu tải dữ liệu'),
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
          _RequestHistoryTile(
            status: 'Đã hoàn tất',
            time: '02/05/2026 09:10',
            file: 'personal_data_20260502.zip',
          ),
          _RequestHistoryTile(
            status: 'Đang xử lý',
            time: '06/05/2026 21:05',
            file: 'Đang chuẩn bị dữ liệu',
          ),
        ],
      ),
    );
  }
}

class _RequestHistoryTile extends StatelessWidget {
  final String status;
  final String time;
  final String file;

  const _RequestHistoryTile({
    required this.status,
    required this.time,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = status == 'Đã hoàn tất';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: ListTile(
        title: Text(file),
        subtitle: Text('$status · $time'),
        trailing: Icon(
          isDone ? Icons.check_circle_outline : Icons.timelapse_outlined,
          color: isDone ? colors.success : colors.warning,
        ),
      ),
    );
  }
}
