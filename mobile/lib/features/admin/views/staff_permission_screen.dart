import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/staff_permission_controller.dart';
import '../data/models/staff_permission.dart';

/// Editor quyền CRUD theo module cho 1 nhân viên SALE
/// (`GET/PUT /permissions/:userId`). ADMIN-only.
class StaffPermissionScreen extends ConsumerStatefulWidget {
  final String userId;
  const StaffPermissionScreen({super.key, required this.userId});

  @override
  ConsumerState<StaffPermissionScreen> createState() =>
      _StaffPermissionScreenState();
}

class _StaffPermissionScreenState extends ConsumerState<StaffPermissionScreen> {
  StaffPermissions? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    final result = await ref
        .read(staffPermissionRepositoryProvider)
        .updatePermissions(widget.userId, draft.modules);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ref.invalidate(staffPermissionsProvider(widget.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final permsAsync = ref.watch(staffPermissionsProvider(widget.userId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Phân quyền nhân viên')),
      body: permsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(staffPermissionsProvider(widget.userId)),
        ),
        data: (server) {
          final perms = _draft ?? server;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(staffPermissionsProvider(widget.userId));
                    await ref
                        .read(staffPermissionsProvider(widget.userId).future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (perms.userName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.bgSurfaceContainer,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.badge_outlined, color: colors.brand),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  perms.userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      ...perms.modules.map(
                        (m) => _ModuleCard(
                          perm: m,
                          onChanged: (updated) => setState(
                              () => _draft = perms.withModule(updated)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Đang lưu...' : 'Lưu phân quyền'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModulePermission perm;
  final ValueChanged<ModulePermission> onChanged;

  const _ModuleCard({required this.perm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(
              perm.moduleLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          _row(context, 'Xem', perm.canRead,
              (v) => onChanged(perm.copyWith(canRead: v))),
          _row(context, 'Tạo', perm.canCreate,
              (v) => onChanged(perm.copyWith(canCreate: v))),
          _row(context, 'Sửa', perm.canUpdate,
              (v) => onChanged(perm.copyWith(canUpdate: v))),
          _row(context, 'Xoá', perm.canDelete,
              (v) => onChanged(perm.copyWith(canDelete: v))),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, bool value,
      ValueChanged<bool> onChanged) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
