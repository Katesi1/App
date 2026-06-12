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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierFormKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_identifierFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final (success, message) = await ref
        .read(authProvider.notifier)
        .forgotPassword(_identifierCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _emailSent = true);
      _showSnackBar(message, isError: false);
    } else {
      _showSnackBar(message, isError: true);
    }
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
                    _emailSent ? 'Kiểm tra email' : 'Quên mật khẩu',
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
                    _emailSent
                        ? 'Chúng tôi đã gửi link đặt lại mật khẩu'
                        : 'Nhập email hoặc số điện thoại đã đăng ký',
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _emailSent
                    ? _buildEmailSent(context)
                    : _buildIdentifierForm(context),
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

  Widget _buildIdentifierForm(BuildContext context) {
    final colors = context.colors;
    return Form(
      key: _identifierFormKey,
      child: Column(
        key: const ValueKey('identifier-form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.jade50,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 40,
                color: AppColors.jade500,
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
            onFieldSubmitted: (_) => _sendResetLink(),
            style: GoogleFonts.beVietnamPro(
                fontSize: 15, color: colors.textPrimary),
            decoration: _inputDecoration(
              context: context,
              hint: 'manager@halong24h.vn',
              icon: Icons.person_outline_rounded,
            ),
            validator: (v) => v?.trim().isEmpty == true
                ? 'Nhập email hoặc số điện thoại'
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Link đặt lại mật khẩu sẽ được gửi qua email (hết hạn sau 10 phút). '
            'Tài khoản chỉ có số điện thoại cần dùng email đã liên kết.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: colors.textTertiary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            label: 'Gửi link đặt lại mật khẩu',
            onTap: _sendResetLink,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                'Quay lại đăng nhập',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppColors.jade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSent(BuildContext context) {
    final colors = context.colors;
    return Column(
      key: const ValueKey('email-sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: colors.success,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.jade50,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.jade50),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nếu tài khoản tồn tại, link đặt lại mật khẩu đã được gửi tới '
                '${_identifierCtrl.text.trim()}.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.jade900,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mở email, bấm link hoặc copy mã trong link. Link hết hạn sau '
                '10 phút.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: colors.textTertiary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'Tôi đã có link — đặt mật khẩu mới',
          onTap: () => context.push('/auth/reset-password'),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _isLoading ? null : _sendResetLink,
              child: Text(
                'Gửi lại link',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.jade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text('|',
                style: TextStyle(color: colors.borderDefault, fontSize: 13)),
            TextButton(
              onPressed: () => setState(() => _emailSent = false),
              child: Text(
                'Đổi tài khoản',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              'Quay lại đăng nhập',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.jade300,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
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
