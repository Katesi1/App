import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/user_provider.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId;
  const UserFormScreen({super.key, this.userId});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'SALE';
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get _isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final result =
        await ref.read(userRepositoryProvider).getUser(widget.userId!);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success && result.data != null) {
      final u = result.data!;
      _nameCtrl.text = u.name;
      _phoneCtrl.text = u.phone;
      _emailCtrl.text = u.email ?? '';
      setState(() {
        _role = u.role;
        _isActive = u.isActive;
      });
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (!_isEdit || _passwordCtrl.text.isNotEmpty)
        'password': _passwordCtrl.text,
      'role': _role,
      if (_isEdit) 'isActive': _isActive,
    };

    final actions = ref.read(userActionsProvider.notifier);
    final ok = _isEdit
        ? await actions.update(widget.userId!, data)
        : await actions.create(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context,
          _isEdit ? 'Cập nhật thành công' : 'Tạo tài khoản thành công');
      context.pop();
    } else {
      final errState = ref.read(userActionsProvider);
      AppSnackBar.error(context,
          errState.hasError ? errState.error.toString() : 'Có lỗi xảy ra');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Sửa tài khoản' : 'Tạo tài khoản mới',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading && _isEdit
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Họ tên *',
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: colors.primary),
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Nhập họ tên' : null,
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: AppSpacing.md),

                    // Phone
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại *',
                        prefixIcon:
                            Icon(Icons.phone_outlined, color: colors.primary),
                      ),
                      validator: (v) => v?.trim().isEmpty == true
                          ? 'Nhập số điện thoại'
                          : null,
                    ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: AppSpacing.md),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon:
                            Icon(Icons.email_outlined, color: colors.primary),
                      ),
                    ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: AppSpacing.md),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: _isEdit
                            ? 'Mật khẩu mới (để trống giữ nguyên)'
                            : 'Mật khẩu *',
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: colors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (!_isEdit && (v?.isEmpty == true)) {
                          return 'Nhập mật khẩu';
                        }
                        if (v?.isNotEmpty == true && v!.length < 6) {
                          return 'Mật khẩu tối thiểu 6 ký tự';
                        }
                        return null;
                      },
                    ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Role selector
                    Text(
                      'Vai trò *',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        _RoleChip(
                          label: 'Sale',
                          value: 'SALE',
                          selected: _role,
                          color: AppColors.primary,
                          onTap: (v) => setState(() => _role = v),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _RoleChip(
                          label: 'Chủ nhà',
                          value: 'OWNER',
                          selected: _role,
                          color: AppColors.completed,
                          onTap: (v) => setState(() => _role = v),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _RoleChip(
                          label: 'Admin',
                          value: 'ADMIN',
                          selected: _role,
                          color: AppColors.error,
                          onTap: (v) => setState(() => _role = v),
                        ),
                      ],
                    ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                    // Active toggle (edit only)
                    if (_isEdit) ...[
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: SwitchListTile(
                          title: Text('Kích hoạt tài khoản',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            _isActive
                                ? 'Tài khoản đang hoạt động'
                                : 'Tài khoản đã vô hiệu',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: _isActive
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          value: _isActive,
                          activeThumbColor: AppColors.success,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Save button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                height: 52,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary)),
                              ),
                            )
                          : FilledButton.icon(
                              key: const ValueKey('save-btn'),
                              onPressed: _save,
                              icon: Icon(_isEdit
                                  ? Icons.save_rounded
                                  : Icons.person_add_rounded),
                              label: Text(
                                _isEdit ? 'Lưu thay đổi' : 'Tạo tài khoản',
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                              ),
                            ),
                    ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Role Chip ────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final ValueChanged<String> onTap;

  const _RoleChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
