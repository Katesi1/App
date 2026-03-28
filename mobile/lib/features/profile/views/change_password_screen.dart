import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/loading_widget.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final (success, message) = await ref
        .read(authProvider.notifier)
        .changePassword(
          _currentPwController.text,
          _newPwController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppSnackBar.success(context, 'Đổi mật khẩu thành công');
      context.pop();
    } else {
      AppSnackBar.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Lock icon ─────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.oceanLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.ocean,
                  size: 36,
                ),
              ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.elasticOut,
                    duration: 500.ms,
                  ),

              const SizedBox(height: 28),

              // ── Current password ──────────────────────────────
              _buildLabel('Mật khẩu hiện tại'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _currentPwController,
                obscureText: !_showCurrent,
                decoration: _pwDecoration(
                  hintText: 'Nhập mật khẩu hiện tại',
                  visible: _showCurrent,
                  onToggle: () =>
                      setState(() => _showCurrent = !_showCurrent),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập mật khẩu hiện tại';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── New password ──────────────────────────────────
              _buildLabel('Mật khẩu mới'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _newPwController,
                obscureText: !_showNew,
                decoration: _pwDecoration(
                  hintText: 'Nhập mật khẩu mới',
                  visible: _showNew,
                  onToggle: () =>
                      setState(() => _showNew = !_showNew),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (v.length < 8) {
                    return 'Mật khẩu cần ít nhất 8 ký tự';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(v)) {
                    return 'Mật khẩu cần có ít nhất 1 chữ hoa';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(v)) {
                    return 'Mật khẩu cần có ít nhất 1 chữ thường';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(v)) {
                    return 'Mật khẩu cần có ít nhất 1 số';
                  }
                  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                      .hasMatch(v)) {
                    return 'Mật khẩu cần có ít nhất 1 ký tự đặc biệt';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Confirm password ──────────────────────────────
              _buildLabel('Xác nhận mật khẩu mới'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPwController,
                obscureText: !_showConfirm,
                decoration: _pwDecoration(
                  hintText: 'Nhập lại mật khẩu mới',
                  visible: _showConfirm,
                  onToggle: () =>
                      setState(() => _showConfirm = !_showConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (v != _newPwController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Hint ──────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.muted, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mật khẩu cần ít nhất 8 ký tự, bao gồm '
                      'chữ hoa, chữ thường, số và ký tự đặc biệt',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Submit button ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ocean,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.xl),
                    ),
                    textStyle: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Đổi mật khẩu'),
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }

  InputDecoration _pwDecoration({
    required String hintText,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.beVietnamPro(color: AppColors.slate),
      prefixIcon: const Icon(Icons.lock_outline_rounded,
          color: AppColors.muted, size: 20),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          visible
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          color: AppColors.slate,
          size: 20,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide:
            const BorderSide(color: AppColors.ocean, width: 1.5),
      ),
    );
  }
}
