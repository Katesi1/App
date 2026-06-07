import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/user_controller.dart';

/// Phân quyền nhân viên (ADMIN-only). Chọn 1 nhân viên SALE → cấu hình quyền
/// CRUD theo module (`GET/PUT /permissions/:userId`).
class RolePermissionScreen extends ConsumerWidget {
  const RolePermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Phân quyền nhân viên')),
      body: staffAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(staffListProvider),
        ),
        data: (users) {
          final sales = users.where((u) => u.isSale).toList();
          return RefreshIndicator(
            color: colors.brand,
            onRefresh: () async => ref.invalidate(staffListProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    'Chọn một nhân viên (SALE) để cấu hình quyền truy cập theo '
                    'từng module. Quyền được lưu riêng cho từng nhân viên.',
                    style: TextStyle(color: colors.textSecondary, height: 1.45),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (sales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyStateWidget(
                      icon: Icons.badge_outlined,
                      message: 'Chưa có nhân viên SALE nào',
                    ),
                  )
                else
                  ...sales.map((u) => _StaffRow(
                        user: u,
                        onTap: () =>
                            context.push('/admin/role-permissions/${u.id}'),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _StaffRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colors.brand.withValues(alpha: 0.12),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style:
                TextStyle(color: colors.textBrand, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(
          user.name.isNotEmpty ? user.name : user.phone,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.email ?? user.phone),
        trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
      ),
    );
  }
}
