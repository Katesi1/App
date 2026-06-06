import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;

  bool _navigated = false;
  bool _minDelayDone = false;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Dismiss native splash và bắt đầu đếm thời gian tối thiểu
    FlutterNativeSplash.remove();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _minDelayDone = true);
        unawaited(_tryNavigate());
      }
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryNavigate() async {
    if (_navigated || !_minDelayDone) return;
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.isLoading) return;

    _navigated = true;
    final user = authState.user;
    final isLoggedIn = authState.isLoggedIn;

    if (!isLoggedIn || user == null) {
      context.go('/login');
      return;
    }

    if (user.isCustomer) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'App dành cho chủ homestay và nhân viên. '
            'Khách lưu trú không đăng nhập được trên app này.',
          ),
        ),
      );
      return;
    }

    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe authProvider xong thì navigate
    ref.listen<AuthState>(authProvider, (_, next) {
      if (!next.isLoading) unawaited(_tryNavigate());
    });

    final size = MediaQuery.of(context).size;

    return Scaffold(
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
                  Color(
                      0xFF083550), // custom interpolation, không thuộc token brand
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
              painter: _SplashWavePainter(_waveCtrl.value),
            ),
          ),

          // ── Center content ─────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulse ring + floating logo
                AnimatedBuilder(
                  animation: Listenable.merge([_floatCtrl, _pulseCtrl]),
                  builder: (_, __) {
                    final floatOffset =
                        math.sin(_floatCtrl.value * math.pi) * 10.0;
                    final pulseScale = 1.0 + _pulseCtrl.value * 0.08;

                    return Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer pulse ring
                          Transform.scale(
                            scale: pulseScale,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.teal.withValues(
                                      alpha: 0.15 * (1 - _pulseCtrl.value)),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          // Inner glow ring
                          Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          // Logo — không clip, không crop
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: Image.asset(
                              'assets/images/logohalong24h.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Text(
                                'HALONG24h',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Brand name
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
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
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 10),

                Text(
                  'Hệ thống quản lý lưu trú Hạ Long',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.4,
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),

          // ── Loading dots ───────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child:
                _LoadingDots().animate(delay: 700.ms).fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

// ── Wave background painter ──────────────────────────────────────────────────

class _SplashWavePainter extends CustomPainter {
  final double progress;
  _SplashWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final t = progress * math.pi * 2;

    // Tần số 1
    paint.color = Colors.white.withValues(alpha: 0.04);
    canvas.drawCircle(
        Offset(size.width * 0.85 + math.sin(t) * 25,
            size.height * 0.12 + math.cos(t) * 30),
        160,
        paint);

    // Tần số 1, phase +π (ngược chiều → trông tự nhiên hơn)
    paint.color = Colors.white.withValues(alpha: 0.03);
    canvas.drawCircle(
        Offset(size.width * 0.1 + math.sin(t + math.pi) * 20,
            size.height * 0.8 + math.cos(t + math.pi) * 20),
        180,
        paint);

    // Tần số 2, phase +π/2
    paint.color = AppColors.jadeBright.withValues(alpha: 0.06);
    canvas.drawCircle(
        Offset(size.width * 0.6 + math.sin(t * 2 + math.pi / 2) * 25,
            size.height * 0.75 + math.cos(t * 2 + math.pi / 2) * 15),
        90,
        paint);
  }

  @override
  bool shouldRepaint(_SplashWavePainter old) => old.progress != progress;
}

// ── Animated loading dots ────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final bounce = math.sin(phase * math.pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              transform: Matrix4.translationValues(0, -bounce * 8, 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.4 + bounce * 0.5),
              ),
            );
          },
        );
      }),
    );
  }
}
