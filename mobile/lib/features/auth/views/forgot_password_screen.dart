import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _tokenCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_identifierFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final (success, message) = await ref
        .read(authProvider.notifier)
        .forgotPassword(_identifierCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _otpSent = true);
      _showSnackBar(message, isError: false);
    } else {
      _showSnackBar(message, isError: true);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final (success, message) = await ref
        .read(authProvider.notifier)
        .resetPassword(_tokenCtrl.text.trim(), _newPasswordCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar(message, isError: false);
      if (mounted) context.go('/login');
    } else {
      _showSnackBar(message, isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.coral : AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Ocean gradient header ────────────────────────
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
                  colors: [AppColors.oceanDeep, AppColors.ocean],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
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
                    _otpSent ? 'Đặt lại mật khẩu' : 'Quên mật khẩu',
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
                    _otpSent
                        ? 'Nhập mã xác nhận và mật khẩu mới'
                        : 'Nhập email hoặc số điện thoại để nhận mã xác nhận',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // ── Form body ────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _otpSent ? _buildResetForm() : _buildIdentifierForm(),
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Enter email/phone ─────────────────────────────
  Widget _buildIdentifierForm() {
    return Form(
      key: _identifierFormKey,
      child: Column(
        key: const ValueKey('identifier-form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.oceanPale,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 40,
                color: AppColors.ocean,
              ),
            ),
          ),
          const SizedBox(height: 24),

          _FieldLabel('EMAIL / SỐ ĐIỆN THOẠI'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _identifierCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendOtp(),
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'manager@halong24h.vn',
              icon: Icons.person_outline_rounded,
            ),
            validator: (v) => v?.trim().isEmpty == true
                ? 'Nhập email hoặc số điện thoại'
                : null,
          ),
          const SizedBox(height: 24),

          _buildActionButton(
            label: 'Gửi mã xác nhận',
            onTap: _sendOtp,
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                'Quay lại đăng nhập',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppColors.oceanMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Enter token + new password ────────────────────
  Widget _buildResetForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset-form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.oceanPale,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.oceanLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.ocean, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mã xác nhận đã được gửi đến ${_identifierCtrl.text.trim()}',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: AppColors.oceanDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Token
          _FieldLabel('MÃ XÁC NHẬN'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _tokenCtrl,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'Nhập mã xác nhận',
              icon: Icons.pin_outlined,
            ),
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Nhập mã xác nhận' : null,
          ),
          const SizedBox(height: 16),

          // New password
          _FieldLabel('MẬT KHẨU MỚI'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordCtrl,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.slate,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nhập mật khẩu mới';
              if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password
          _FieldLabel('XÁC NHẬN MẬT KHẨU'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.slate,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Xác nhận mật khẩu';
              if (v != _newPasswordCtrl.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),
          const SizedBox(height: 24),

          _buildActionButton(
            label: 'Đặt lại mật khẩu',
            onTap: _resetPassword,
          ),

          const SizedBox(height: 12),

          // Resend + back
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: Text(
                  'Gửi lại mã',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppColors.oceanMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text('|',
                  style: TextStyle(color: AppColors.border, fontSize: 13)),
              TextButton(
                onPressed: () => setState(() => _otpSent = false),
                child: Text(
                  'Đổi tài khoản',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared action button ──────────────────────────────────
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
                    color: AppColors.ocean,
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
                    colors: [AppColors.oceanMid, AppColors.ocean],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ocean.withValues(alpha: 0.3),
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

  // ── Input decoration helper ───────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.slate),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
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
        borderSide: const BorderSide(color: AppColors.oceanMid, width: 1.5),
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
        color: AppColors.muted,
        letterSpacing: 0.5,
      ),
    );
  }
}
