import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  bool _confirmedPolicy = false;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canDelete = _confirmCtrl.text.trim().toUpperCase() == 'DELETE';
    return Scaffold(
      appBar: AppBar(title: const Text('Xóa tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.errorBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'Hành động này không thể hoàn tác. Sau khi xóa tài khoản, '
              'bạn sẽ mất quyền truy cập lịch sử và dữ liệu liên quan.',
              style: TextStyle(color: colors.error, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Nhập DELETE để xác nhận'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _confirmCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Xác nhận',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmedPolicy,
            onChanged: (v) => setState(() => _confirmedPolicy = v ?? false),
            title:
                const Text('Tôi hiểu rằng dữ liệu có thể không khôi phục được'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: canDelete && _confirmedPolicy
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã tạo yêu cầu xóa tài khoản'),
                      ),
                    );
                  }
                : null,
            child: const Text('Gửi yêu cầu xóa'),
          ),
        ],
      ),
    );
  }
}
