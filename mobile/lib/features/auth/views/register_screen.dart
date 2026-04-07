import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  late final AnimationController _waveCtrl;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Chỉ hỗ trợ STAFF — giữ lại để dễ mở rộng sau
  final UserRole _role = UserRole.staff;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _role.value,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    final error = await ref
        .read(authProvider.notifier)
        .signInWithGoogle(role: _role.value);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background gradient ────────────────────────────────
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.oceanDeep,
                  Color(0xFF0A3D5C),
                  AppColors.ocean,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Animated wave circles ──────────────────────────────
          AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _RegisterWavePainter(_waveCtrl.value),
            ),
          ),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                // ── Hero section ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/images/logohalong24h.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(
                              'HALONG24h',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ).animate().scale(
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1.0, 1.0),
                          duration: 500.ms,
                          curve: Curves.elasticOut),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              children: const [
                                TextSpan(text: 'Halong'),
                                TextSpan(
                                  text: '24h',
                                  style: TextStyle(color: AppColors.gold),
                                ),
                              ],
                            ),
                          )
                              .animate(delay: 100.ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                          const SizedBox(height: 4),
                          Text(
                            'Tạo tài khoản quản lý',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Form card ─────────────────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Role badge
                            _StaffBadge()
                                .animate(delay: 350.ms)
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: -0.1, end: 0),

                            const SizedBox(height: 20),

                            // Họ tên
                            _buildField(
                              delay: 400.ms,
                              child: TextFormField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.beVietnamPro(
                                    fontSize: 15, color: AppColors.ink),
                                decoration: _inputDecor(
                                  label: 'Họ và tên',
                                  hint: 'Nguyễn Văn A',
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Nhập họ tên';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Tối thiểu 2 ký tự';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Số điện thoại
                            _buildField(
                              delay: 460.ms,
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.beVietnamPro(
                                    fontSize: 15, color: AppColors.ink),
                                decoration: _inputDecor(
                                  label: 'Số điện thoại',
                                  hint: '0912 345 678',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Nhập số điện thoại';
                                  }
                                  if (!RegExp(r'^0\d{9,10}$')
                                      .hasMatch(v.trim())) {
                                    return 'Số điện thoại không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Mật khẩu
                            _buildField(
                              delay: 520.ms,
                              child: TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.beVietnamPro(
                                    fontSize: 15, color: AppColors.ink),
                                decoration: _inputDecor(
                                  label: 'Mật khẩu',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.slate,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Nhập mật khẩu';
                                  }
                                  if (v.length < 6) {
                                    return 'Tối thiểu 6 ký tự';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Xác nhận mật khẩu
                            _buildField(
                              delay: 580.ms,
                              child: TextFormField(
                                controller: _confirmPasswordCtrl,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(),
                                style: GoogleFonts.beVietnamPro(
                                    fontSize: 15, color: AppColors.ink),
                                decoration: _inputDecor(
                                  label: 'Xác nhận mật khẩu',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.slate,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Nhập lại mật khẩu';
                                  }
                                  if (v != _passwordCtrl.text) {
                                    return 'Mật khẩu không khớp';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Register button
                            _RegisterButton(
                              isLoading: _isLoading,
                              onTap: _register,
                            )
                                .animate(delay: 640.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, end: 0),

                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                const Expanded(
                                    child: Divider(
                                        color: AppColors.border, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'hoặc',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppColors.slate,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                    child: Divider(
                                        color: AppColors.border, thickness: 1)),
                              ],
                            ).animate(delay: 680.ms).fadeIn(duration: 400.ms),

                            const SizedBox(height: 16),

                            // Google button
                            _GoogleRegisterButton(
                              isLoading: _isLoading,
                              onTap: _registerWithGoogle,
                            )
                                .animate(delay: 720.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 24),

                            // Login link
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Đã có tài khoản? ',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      color: AppColors.slate,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: Text(
                                      'Đăng nhập ngay',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.oceanMid,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(delay: 760.ms).fadeIn(duration: 400.ms),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: 300.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      curve: Curves.easeOutCubic,
                      duration: 600.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({required Duration delay, required Widget child}) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  InputDecoration _inputDecor({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.beVietnamPro(
        fontSize: 14,
        color: AppColors.slate,
      ),
      hintStyle: GoogleFonts.beVietnamPro(
        fontSize: 14,
        color: AppColors.slate.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(icon, color: AppColors.slate, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.ocean, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.coral, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
      ),
    );
  }
}

// ── Staff badge ──────────────────────────────────────────────────────────────

class _StaffBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ocean.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.ocean.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.ocean.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.manage_accounts_outlined,
              color: AppColors.ocean,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài khoản Quản lý',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ocean,
                ),
              ),
              Text(
                'Quản lý phòng & booking',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.ocean, size: 18),
        ],
      ),
    );
  }
}

// ── Register button with press animation ─────────────────────────────────────

class _RegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _RegisterButton({required this.isLoading, required this.onTap});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _pressCtrl.value, child: child),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.ocean, AppColors.oceanMid],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.ocean.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    key: const ValueKey('text'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tạo tài khoản',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Google register button ───────────────────────────────────────────────────

class _GoogleRegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleRegisterButton(
      {required this.isLoading, required this.onTap});

  @override
  State<_GoogleRegisterButton> createState() => _GoogleRegisterButtonState();
}

class _GoogleRegisterButtonState extends State<_GoogleRegisterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _pressCtrl.value, child: child),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/google_logo.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Đăng ký bằng Google',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wave background painter ──────────────────────────────────────────────────

class _RegisterWavePainter extends CustomPainter {
  final double progress;
  _RegisterWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final t = progress * math.pi * 2;

    // Tần số 1
    paint.color = const Color(0x0AFFFFFF);
    canvas.drawCircle(
        Offset(size.width * 0.9 + math.sin(t) * 20,
            size.height * 0.08 + math.cos(t) * 20),
        150,
        paint);

    // Tần số 1, phase +π
    paint.color = const Color(0x08FFFFFF);
    canvas.drawCircle(
        Offset(-40 + math.sin(t + math.pi) * 25,
            size.height * 0.25 + math.cos(t + math.pi) * 15),
        120,
        paint);

    // Tần số 2
    paint.color = const Color(0x0D00B4D8);
    canvas.drawCircle(
        Offset(size.width * 0.5 + math.sin(t * 2) * 20,
            size.height * 0.18 + math.cos(t * 2) * 10),
        70,
        paint);
  }

  @override
  bool shouldRepaint(_RegisterWavePainter old) =>
      old.progress != progress;
}
