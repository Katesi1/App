import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import 'role_picker_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _shakeCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _waveCtrl;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

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
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await SecureStorage.getSavedCredentials();
    if (saved == null || !mounted) return;
    setState(() {
      _emailCtrl.text = saved.email;
      _passwordCtrl.text = saved.password;
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _shakeCtrl.dispose();
    _floatCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final identifier = _normalizeIdentifier(_emailCtrl.text);
    final password = _passwordCtrl.text;
    final error =
        await ref.read(authProvider.notifier).login(identifier, password);
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
      return;
    }

    // Đăng nhập thành công → lưu hoặc xoá credentials theo checkbox
    if (_rememberMe) {
      await SecureStorage.saveCredentials(identifier, password);
    } else {
      await SecureStorage.clearCredentials();
    }
  }

  String _normalizeIdentifier(String raw) {
    var v = raw.trim();
    // Remove spaces commonly inserted in phone numbers
    v = v.replaceAll(' ', '');

    // Normalize VN phone formats to match DB (usually stored as 0xxxxxxxxx)
    if (!v.contains('@')) {
      if (v.startsWith('+84') && v.length > 3) {
        v = '0${v.substring(3)}';
      } else if (v.startsWith('84') && v.length >= 11) {
        v = '0${v.substring(2)}';
      }
    }

    return v;
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final outcome = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    _handleSocialOutcome(outcome);
  }

  Future<void> _loginWithApple() async {
    setState(() => _isLoading = true);
    final outcome = await ref.read(authProvider.notifier).signInWithApple();
    if (!mounted) return;
    setState(() => _isLoading = false);
    _handleSocialOutcome(outcome, provider: SocialProvider.apple);
  }

  void _handleSocialOutcome(
    GoogleSignInOutcome outcome, {
    SocialProvider provider = SocialProvider.google,
  }) {
    switch (outcome) {
      case GoogleSignInSuccess():
        return;
      case GoogleSignInNeedsRole():
        context.push(
          '/auth/role-picker',
          extra: RolePickerArgs(
            idToken: outcome.idToken,
            profile: outcome.profile,
            provider: provider,
          ),
        );
      case GoogleSignInCancelled():
        return;
      case GoogleSignInFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    // Detect force-logout (token refresh fail) → show snackbar 1 lần.
    ref.listen(authProvider, (prev, next) {
      if (next.forceLoggedOut && (prev?.forceLoggedOut ?? false) == false) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.lock_clock_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.coral,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        // Clear flag để snackbar không hiện lại khi user back-vào lại screen.
        ref.read(authProvider.notifier).consumeForceLogoutFlag();
      }
    });

    return Stack(
      children: [
        // ── Background gradient (ngoài Scaffold để keyboard không ảnh hưởng) ──
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.oceanDeep,
                  Color(
                      0xFF0A3D5C), // custom interpolation, không thuộc token brand
                  AppColors.ocean,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // ── Animated wave circles (ngoài Scaffold) ──────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _WavePainter(_waveCtrl.value),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              bottom: false,
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
                                final offset =
                                    math.sin(_floatCtrl.value * math.pi) * 8.0;
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
                                      color:
                                          AppColors.teal.withValues(alpha: 0.3),
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
                            ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
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
                              padding: EdgeInsets.fromLTRB(
                                  28, 32, 28, 24 + bottomInset),
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
                                    )
                                        .animate(delay: 400.ms)
                                        .fadeIn(duration: 400.ms)
                                        .slideX(begin: -0.1, end: 0),

                                    const SizedBox(height: 4),

                                    Text(
                                      'Đăng nhập để tiếp tục quản lý',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 13,
                                        color: AppColors.slate,
                                      ),
                                    )
                                        .animate(delay: 450.ms)
                                        .fadeIn(duration: 400.ms),

                                    const SizedBox(height: 28),

                                    // Email / Phone field
                                    _AnimatedField(
                                      delay: 500.ms,
                                      child: TextFormField(
                                        controller: _emailCtrl,
                                        keyboardType: TextInputType.text,
                                        textInputAction: TextInputAction.next,
                                        style: GoogleFonts.beVietnamPro(
                                            fontSize: 15, color: AppColors.ink),
                                        decoration: _inputDecor(
                                          label: 'Email / Số điện thoại',
                                          hint: '',
                                          icon: Icons.email_outlined,
                                        ),
                                        validator: (v) => v?.trim().isEmpty ==
                                                true
                                            ? 'Nhập email hoặc số điện thoại'
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
                                            fontSize: 15, color: AppColors.ink),
                                        decoration: _inputDecor(
                                          label: 'Mật khẩu',
                                          hint: '',
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
                                        validator: (v) => v?.isEmpty == true
                                            ? 'Nhập mật khẩu'
                                            : null,
                                      ),
                                    ),

                                    // Remember me + Forgot password
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Remember me checkbox
                                        InkWell(
                                          onTap: () => setState(
                                              () => _rememberMe = !_rememberMe),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: Checkbox(
                                                    value: _rememberMe,
                                                    onChanged: (v) => setState(
                                                        () => _rememberMe =
                                                            v ?? false),
                                                    activeColor:
                                                        AppColors.ocean,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Ghi nhớ tài khoản',
                                                  style:
                                                      GoogleFonts.beVietnamPro(
                                                    fontSize: 13,
                                                    color: AppColors.slate,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Forgot password
                                        TextButton(
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
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    // Login button
                                    _LoginButton(
                                      isLoading: _isLoading,
                                      onTap: _login,
                                    )
                                        .animate(delay: 650.ms)
                                        .fadeIn(duration: 400.ms)
                                        .slideY(begin: 0.2, end: 0),

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
                                    )
                                        .animate(delay: 700.ms)
                                        .fadeIn(duration: 400.ms),

                                    const SizedBox(height: 20),

                                    // Google button
                                    _GoogleButton(
                                      isLoading: _isLoading,
                                      onTap: _loginWithGoogle,
                                    )
                                        .animate(delay: 750.ms)
                                        .fadeIn(duration: 400.ms)
                                        .slideY(begin: 0.1, end: 0),

                                    // Apple button — chỉ hiện trên iOS theo
                                    // Apple Guideline 4.8 (Android không bắt buộc).
                                    if (Platform.isIOS) ...[
                                      const SizedBox(height: 12),
                                      _AppleButton(
                                        isLoading: _isLoading,
                                        onTap: _loginWithApple,
                                      )
                                          .animate(delay: 800.ms)
                                          .fadeIn(duration: 400.ms)
                                          .slideY(begin: 0.1, end: 0),
                                    ],

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
                                    )
                                        .animate(delay: 800.ms)
                                        .fadeIn(duration: 400.ms),

                                    const SizedBox(height: 12),

                                    // Invite-by-email entry — cho nhân viên
                                    Center(
                                      child: GestureDetector(
                                        onTap: () =>
                                            context.push('/staff/accept'),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 12),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.qr_code_2_rounded,
                                                size: 14,
                                                color: AppColors.muted,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tôi có mã nhân viên',
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                        .animate(delay: 850.ms)
                                        .fadeIn(duration: 400.ms),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final t = progress * math.pi * 2;

    // Large circle top-right — tần số 1 (1 vòng đầy đủ)
    paint.color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(
      Offset(size.width + 40 + math.sin(t) * 20, -60 + math.cos(t) * 30),
      180,
      paint,
    );

    // Medium circle bottom-left — tần số 1, phase +π (ngược chiều)
    paint.color = Colors.white.withValues(alpha: 0.03);
    canvas.drawCircle(
      Offset(-60 + math.sin(t + math.pi) * 40,
          size.height * 0.35 + math.cos(t + math.pi) * 20),
      140,
      paint,
    );

    // Small teal accent — tần số 2 (2 vòng, nhanh hơn)
    paint.color = AppColors.jadeBright.withValues(alpha: 0.07);
    canvas.drawCircle(
      Offset(size.width * 0.7 + math.sin(t * 2) * 18,
          size.height * 0.25 + math.cos(t * 2) * 14),
      80,
      paint,
    );

    // Gold accent dot — tần số 1, phase +π/2
    paint.color = AppColors.gold500.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width * 0.15 + math.cos(t + math.pi / 2) * 10,
          size.height * 0.2 + math.sin(t + math.pi / 2) * 10),
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

// ── Apple button (iOS only) ───────────────────────────────────────────────────

class _AppleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AppleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'Đăng nhập bằng Apple',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
