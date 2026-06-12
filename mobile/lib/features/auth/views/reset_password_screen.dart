import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/auth_controller.dart';

/// Đặt lại mật khẩu — entry từ link email
/// (`/auth/reset-password?token=...`) hoặc nhập token thủ công.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// JWT từ query `?token=` trong link email (hết hạn 10 phút).
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _hasPrefilledToken =>
      widget.initialToken != null && widget.initialToken!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasPrefilledToken) {
      _tokenCtrl.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final (success, message) =
        await ref.read(authProvider.notifier).resetPassword(
              _tokenCtrl.text.trim(),
              _newPasswordCtrl.text,
            );

    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSnackBar(message, isError: !success);
    if (success && mounted) context.go('/login');
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (isError) {
      AppToast.error(context, message);
    } else {
      AppToast.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgSurface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 28,
                right: 28,
                bottom: 32,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.4, -1),
                  end: Alignment(0.4, 1),
                  colors: [AppColors.jade900, AppColors.jade500],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đặt lại mật khẩu',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    _hasPrefilledToken
                        ? 'Nhập mật khẩu mới cho tài khoản của bạn'
                        : 'Nhập mã từ link email và mật khẩu mới',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasPrefilledToken) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.jade50,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.jade50),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              color: AppColors.jade500,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Link đặt lại mật khẩu hợp lệ. '
                                'Mã hết hạn sau 10 phút.',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  color: AppColors.jade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      _FieldLabel('MÃ TỪ LINK EMAIL'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tokenCtrl,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 15, color: colors.textPrimary),
                        decoration: _inputDecoration(
                          context: context,
                          hint: 'Dán mã từ link email',
                          icon: Icons.link_outlined,
                        ),
                        validator: (v) => v?.trim().isEmpty == true
                            ? 'Nhập mã từ link email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _FieldLabel('MẬT KHẨU MỚI'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _newPasswordCtrl,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 15, color: colors.textPrimary),
                      decoration: _inputDecoration(
                        context: context,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colors.textTertiary,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập mật khẩu mới';
                        if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('XÁC NHẬN MẬT KHẨU'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _resetPassword(),
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 15, color: colors.textPrimary),
                      decoration: _inputDecoration(
                        context: context,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: colors.textTertiary,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Xác nhận mật khẩu';
                        if (v != _newPasswordCtrl.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      label: 'Đặt lại mật khẩu',
                      onTap: _resetPassword,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: Text(
                          'Gửi lại link qua email',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: AppColors.jade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                height: 52,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.jade500,
                  ),
                ),
              ),
            )
          : SizedBox(
              key: ValueKey(label),
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.jade300, AppColors.jade500],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.jade500.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: colors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.bgCanvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.jade300, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.colors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }
}
