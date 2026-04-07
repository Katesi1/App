import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _shakeCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _waveCtrl;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _shakeCtrl.dispose();
    _floatCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error = await ref.read(authProvider.notifier).login(
          _phoneCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      _shakeCtrl.forward(from: 0);
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final error = await ref.read(authProvider.notifier).signInWithGoogle();
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
    final topPadding = MediaQuery.of(context).padding.top;

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
            builder: (_, __) {
              return CustomPaint(
                size: size,
                painter: _WavePainter(_waveCtrl.value),
              );
            },
          ),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: size.height - topPadding,
                child: Column(
                  children: [
                    // ── Logo section ─────────────────────────────
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Floating logo
                          AnimatedBuilder(
                            animation: _floatCtrl,
                            builder: (_, child) {
                              final offset = math.sin(
                                      _floatCtrl.value * math.pi) *
                                  8.0;
                              return Transform.translate(
                                offset: Offset(0, offset),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logohalong24h.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(
                                  'HALONG24h',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ).animate().scale(
                                  begin: const Offset(0.5, 0.5),
                                  end: const Offset(1.0, 1.0),
                                  duration: 600.ms,
                                  curve: Curves.elasticOut,
                                ),
                          ),

                          const SizedBox(height: 20),

                          // Brand name
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
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
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 8),

                          Text(
                            'Hệ thống quản lý lưu trú Hạ Long',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 0.3,
                            ),
                          )
                              .animate(delay: 350.ms)
                              .fadeIn(duration: 500.ms),
                        ],
                      ),
                    ),

                    // ── Form card ─────────────────────────────────
                    Expanded(
                      flex: 7,
                      child: AnimatedBuilder(
                        animation: _shakeCtrl,
                        builder: (context, child) {
                          final offset = _shakeCtrl.isAnimating
                              ? 8 *
                                  (1 - _shakeCtrl.value) *
                                  ((_shakeCtrl.value * 10).floor() % 2 == 0
                                      ? 1
                                      : -1)
                              : 0.0;
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
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
                            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Handle indicator
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin:
                                          const EdgeInsets.only(bottom: 24),
                                      decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),

                                  Text(
                                    'Chào mừng trở lại',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ).animate(delay: 400.ms).fadeIn(
                                      duration: 400.ms).slideX(
                                      begin: -0.1, end: 0),

                                  const SizedBox(height: 4),

                                  Text(
                                    'Đăng nhập để tiếp tục quản lý',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      color: AppColors.slate,
                                    ),
                                  ).animate(delay: 450.ms).fadeIn(
                                      duration: 400.ms),

                                  const SizedBox(height: 28),

                                  // Phone / Email field
                                  _AnimatedField(
                                    delay: 500.ms,
                                    child: TextFormField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      style: GoogleFonts.beVietnamPro(
                                          fontSize: 15,
                                          color: AppColors.ink),
                                      decoration: _inputDecor(
                                        label: 'Email / Số điện thoại',
                                        hint: 'manager@halong24h.vn',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      validator: (v) =>
                                          v?.trim().isEmpty == true
                                              ? 'Nhập tài khoản'
                                              : null,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Password field
                                  _AnimatedField(
                                    delay: 580.ms,
                                    child: TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _login(),
                                      style: GoogleFonts.beVietnamPro(
                                          fontSize: 15,
                                          color: AppColors.ink),
                                      decoration: _inputDecor(
                                        label: 'Mật khẩu',
                                        hint: '••••••••',
                                        icon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                            color: AppColors.slate,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),
                                      validator: (v) =>
                                          v?.isEmpty == true
                                              ? 'Nhập mật khẩu'
                                              : null,
                                    ),
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          context.go('/forgot-password'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 4),
                                      ),
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          color: AppColors.oceanMid,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Login button
                                  _LoginButton(
                                    isLoading: _isLoading,
                                    onTap: _login,
                                  ).animate(delay: 650.ms).fadeIn(
                                      duration: 400.ms).slideY(
                                      begin: 0.2, end: 0),

                                  const SizedBox(height: 24),

                                  // Divider
                                  Row(
                                    children: [
                                      const Expanded(
                                          child: Divider(
                                              color: AppColors.border,
                                              thickness: 1)),
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
                                              color: AppColors.border,
                                              thickness: 1)),
                                    ],
                                  ).animate(delay: 700.ms).fadeIn(
                                      duration: 400.ms),

                                  const SizedBox(height: 20),

                                  // Google button
                                  _GoogleButton(
                                    isLoading: _isLoading,
                                    onTap: _loginWithGoogle,
                                  ).animate(delay: 750.ms).fadeIn(
                                      duration: 400.ms).slideY(
                                      begin: 0.1, end: 0),

                                  const SizedBox(height: 28),

                                  // Register link
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Chưa có tài khoản? ',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 13,
                                            color: AppColors.slate,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              context.go('/register'),
                                          child: Text(
                                            'Đăng ký ngay',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.oceanMid,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate(delay: 800.ms).fadeIn(
                                      duration: 400.ms),
                                ],
                              ),
                            ),
                          ),
                        ).animate(delay: 300.ms).slideY(
                            begin: 0.15, end: 0, curve: Curves.easeOutCubic,
                            duration: 600.ms),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

// ── Wave background painter ──────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large circle top-right
    paint.color = const Color(0x0DFFFFFF);
    canvas.drawCircle(
      Offset(size.width + 40 - progress * 20, -60 + progress * 30),
      180,
      paint,
    );

    // Medium circle bottom-left
    paint.color = const Color(0x08FFFFFF);
    canvas.drawCircle(
      Offset(-60 + progress * 40, size.height * 0.35 - progress * 20),
      140,
      paint,
    );

    // Small teal accent
    paint.color = const Color(0x1200B4D8);
    canvas.drawCircle(
      Offset(size.width * 0.7 + math.sin(progress * math.pi * 2) * 20,
          size.height * 0.25 + math.cos(progress * math.pi * 2) * 15),
      80,
      paint,
    );

    // Gold accent dot
    paint.color = const Color(0x15C9A84C);
    canvas.drawCircle(
      Offset(size.width * 0.15 + math.cos(progress * math.pi * 2) * 10,
          size.height * 0.2 + math.sin(progress * math.pi * 2) * 10),
      50,
      paint,
    );
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Animated field wrapper ───────────────────────────────────────────────────

class _AnimatedField extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedField({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

// ── Login button with press animation ───────────────────────────────────────

class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

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
    _scaleAnim = _pressCtrl;
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
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
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
                        'Đăng nhập',
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

// ── Google button ────────────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton>
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
                'Đăng nhập bằng Google',
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
