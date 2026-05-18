import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';

/// Camera frame overlay with 4 corner brackets + scan line gradient.
///
/// Calm operations: NO glow shadow, only corner brackets + subtle scan line.
class CameraFrameOverlay extends StatefulWidget {
  /// Center hint icon (only shown when [showCenterHint] = true).
  final IconData centerIcon;
  final String hintTitle;
  final String hintSubtitle;
  final bool showCenterHint;
  final double aspectRatio;

  const CameraFrameOverlay({
    super.key,
    this.centerIcon = Icons.credit_card_outlined,
    this.hintTitle = 'Đặt CCCD vào khung',
    this.hintSubtitle = 'Tự động chụp khi nhận diện',
    this.showCenterHint = true,
    this.aspectRatio = 16 / 10,
  });

  @override
  State<CameraFrameOverlay> createState() => _CameraFrameOverlayState();
}

class _CameraFrameOverlayState extends State<CameraFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F23), // deeper than canvas
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // 4 corner brackets
            Positioned(
                left: 16, top: 16, child: _Corner(color: AppColors.jadeText)),
            Positioned(
                right: 16,
                top: 16,
                child: _Corner(color: AppColors.jadeText, rotate: 1)),
            Positioned(
                left: 16,
                bottom: 16,
                child: _Corner(color: AppColors.jadeText, rotate: 3)),
            Positioned(
                right: 16,
                bottom: 16,
                child: _Corner(color: AppColors.jadeText, rotate: 2)),

            // Scan line
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (_, __) {
                return Positioned(
                  left: 16,
                  right: 16,
                  top: 16 +
                      (MediaQuery.of(context).size.width - 32) *
                          0.62 *
                          _scanCtrl.value,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.jadeMuted.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Center hint
            if (widget.showCenterHint)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.borderDefault,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.centerIcon,
                        size: 22,
                        color: AppColors.jadeMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.hintTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.hintSubtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single 18×18 corner bracket with 2.5px border.
/// [rotate] = 0..3 — number of 90° clockwise rotations.
class _Corner extends StatelessWidget {
  final Color color;
  final int rotate;
  const _Corner({required this.color, this.rotate = 0});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: rotate,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _CornerPainter(color: color)),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Oval frame for selfie (vs the rectangular CCCD frame).
class SelfieFrameOverlay extends StatelessWidget {
  final String hintText;

  const SelfieFrameOverlay({super.key, required this.hintText});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: 16 / 12,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F23),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Oval dashed border
            CustomPaint(
              size: const Size(140, 180),
              painter: _OvalDashedPainter(color: const Color(0xFF4A5560)),
            ),
            // Person icon center
            Icon(
              Icons.person_outline,
              size: 56,
              color: colors.textTertiary.withValues(alpha: 0.5),
            ),
            // Live status indicator
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hintText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OvalDashedPainter extends CustomPainter {
  final Color color;
  _OvalDashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addOval(rect);

    // Dashed effect
    final pathMetrics = path.computeMetrics();
    for (final pm in pathMetrics) {
      double distance = 0;
      while (distance < pm.length) {
        final segment = pm.extractPath(distance, distance + 6);
        canvas.drawPath(segment, paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OvalDashedPainter oldDelegate) =>
      oldDelegate.color != color;
}
