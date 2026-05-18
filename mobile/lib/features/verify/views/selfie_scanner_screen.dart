import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// Pose thresholds (degrees) — top-level so `_Challenge.matches()` can use them.
// ML Kit: yaw > 0 = face turned to image's right (= user turn head LEFT do
// front-cam mirrored display). pitch > 0 = looking up.
const double _yawThreshold = 18.0;
const double _pitchThreshold = 12.0;
const double _neutralTolerance = 8.0;

/// Full-screen selfie scanner with **liveness challenge** + min-5s gate.
///
/// Anti-bot / anti-replay flow:
/// 1. User enters → find face + ensure quality (centered, large, eyes open).
/// 2. 4 liveness actions are **shuffled randomly** each session
///    (left/right/up/down) so pre-recorded bots can't pass.
/// 3. Each action must hold the pose ≥ 1.2s (6 frames) → reduces false positives.
/// 4. After 4 actions → user returns to neutral → system captures.
/// 5. **Hard floor 5s**: if the user finishes faster → wait the countdown to
///    5s before allowing capture.
///
/// Pops the parent with `File?` (raw selfie, not cropped — face match needs
/// the surrounding context).
class SelfieScannerScreen extends StatefulWidget {
  const SelfieScannerScreen({super.key});

  @override
  State<SelfieScannerScreen> createState() => _SelfieScannerScreenState();
}

class _SelfieScannerScreenState extends State<SelfieScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  FaceDetector? _detector;
  bool _initializing = true;
  String? _initError;

  bool _processing = false;
  DateTime _lastProcessAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _capturing = false;

  // ── Liveness state ──────────────────────────────────────────────────
  late final List<_Challenge> _challenges;
  int _currentIdx = 0;
  int _holdFrames = 0;

  // Hard floor min duration — starts the moment the screen opens, regardless
  // of how fast the user completes actions. If they finish early → countdown overlay.
  static const Duration _minDuration = Duration(seconds: 5);
  late final DateTime _startedAt;
  Timer? _minDurationTimer;
  bool _minDurationMet = false;
  Timer? _tickTimer; // 1 Hz tick to re-render countdown

  // ── Detection thresholds ────────────────────────────────────────────
  static const Duration _processInterval = Duration(milliseconds: 200);
  static const int _challengeHoldThreshold = 6; // ~1.2s pose hold
  static const int _neutralHoldThreshold = 5; // ~1s neutral final

  // Pose thresholds — declared top-level (see `_yawThreshold` etc. at the top
  // of the file) so the `_Challenge.matches()` enum can share the same values.

  // Face quality (initial gate before entering the challenge).
  static const double _minFaceFraction = 0.22;
  static const double _maxOffsetX = 0.25;
  static const double _maxOffsetY = 0.28;
  static const double _minEyeOpenProb = 0.4;

  static const _orientationDegrees = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  _Phase _phase = _Phase.searching;
  _PositionHint _positionHint = _PositionHint.searching;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Shuffle 4 challenges — different order each time the scanner opens.
    _challenges = [..._Challenge.values]..shuffle(math.Random.secure());
    _startedAt = DateTime.now();

    // Hard floor: timer runs independently of user actions.
    _minDurationTimer = Timer(_minDuration, () {
      if (mounted) setState(() => _minDurationMet = true);
    });
    // Tick once per second to re-render countdown text (only near the end).
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_minDurationMet) setState(() {});
    });

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.2,
      ),
    );
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _minDurationTimer?.cancel();
    _tickTimer?.cancel();
    _shutdown();
    super.dispose();
  }

  Future<void> _shutdown() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      try {
        if (c.value.isStreamingImages) {
          await c.stopImageStream();
        }
      } catch (_) {}
      await c.dispose();
    }
    await _detector?.close();
    _detector = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _shutdown();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _initError = 'Thiết bị không có camera khả dụng.';
          _initializing = false;
        });
        return;
      }
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );

      final controller = CameraController(
        front,
        // Medium (~640×480) is enough for ML Kit face detection and uses
        // ~75% less RAM/GPU than high → avoids thermal throttling on older
        // iPhones during continuous streaming.
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      await controller.startImageStream(_onFrame);

      setState(() {
        _initializing = false;
        _initError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = 'Không khởi tạo được camera trước: $e';
          _initializing = false;
        });
      }
    }
  }

  // ─── Frame processing ────────────────────────────────────────────────

  Future<void> _onFrame(CameraImage image) async {
    if (_processing || _capturing) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessAt) < _processInterval) return;
    _lastProcessAt = now;
    _processing = true;

    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final faces = await _detector?.processImage(input);
      if (faces == null || !mounted) return;

      _processFrame(faces, image.width, image.height);
    } catch (e) {
      if (kDebugMode) debugPrint('[selfie scanner] frame err: $e');
    } finally {
      _processing = false;
    }
  }

  /// Phase machine driver — called every frame (~200ms).
  void _processFrame(List<Face> faces, int imgW, int imgH) {
    // Guard: must have exactly 1 face.
    if (faces.isEmpty) {
      _setPhase(_Phase.searching, hint: _PositionHint.searching);
      _holdFrames = 0;
      return;
    }
    if (faces.length > 1) {
      _setPhase(_Phase.searching, hint: _PositionHint.multipleFaces);
      _holdFrames = 0;
      return;
    }

    final face = faces.first;
    final box = face.boundingBox;
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;

    // Phase 1: positioning — ensure face quality is OK before entering challenge.
    if (_phase == _Phase.searching) {
      final faceFraction = box.width / imgW;
      if (faceFraction < _minFaceFraction) {
        _setPhase(_Phase.searching, hint: _PositionHint.tooFar);
        return;
      }
      final dx = (box.center.dx - imgW / 2).abs() / imgW;
      final dy = (box.center.dy - imgH / 2).abs() / imgH;
      if (dx > _maxOffsetX || dy > _maxOffsetY) {
        _setPhase(_Phase.searching, hint: _PositionHint.offCenter);
        return;
      }
      if (leftEye < _minEyeOpenProb || rightEye < _minEyeOpenProb) {
        _setPhase(_Phase.searching, hint: _PositionHint.eyesClosed);
        return;
      }
      // Require looking straight initially → prevents users from "cheating"
      // by holding a pose that already matches the first challenge.
      if (yaw.abs() > _neutralTolerance || pitch.abs() > _neutralTolerance) {
        _setPhase(_Phase.searching, hint: _PositionHint.notStraight);
        return;
      }
      // Quality OK → enter challenge phase.
      _setPhase(_Phase.challenge);
      _holdFrames = 0;
      return;
    }

    // Phase 2: challenge sequencing.
    if (_phase == _Phase.challenge) {
      // Still need to see the face — strict quality not required.
      final current = _challenges[_currentIdx];
      if (current.matches(yaw, pitch)) {
        _holdFrames++;
        if (mounted) setState(() {}); // re-render progress
        if (_holdFrames >= _challengeHoldThreshold) {
          // Challenge done — advance or move to neutral phase.
          _holdFrames = 0;
          if (_currentIdx + 1 >= _challenges.length) {
            _setPhase(_Phase.neutral);
          } else {
            setState(() => _currentIdx++);
          }
        }
      } else {
        if (_holdFrames != 0) {
          _holdFrames = 0;
          if (mounted) setState(() {});
        }
      }
      return;
    }

    // Phase 3: final neutral pose.
    if (_phase == _Phase.neutral) {
      final isNeutral = yaw.abs() <= _neutralTolerance &&
          pitch.abs() <= _neutralTolerance &&
          leftEye >= _minEyeOpenProb &&
          rightEye >= _minEyeOpenProb;
      if (isNeutral) {
        _holdFrames++;
        if (mounted) setState(() {});
        if (_holdFrames >= _neutralHoldThreshold && _minDurationMet) {
          _capture();
        }
      } else {
        if (_holdFrames != 0) {
          _holdFrames = 0;
          if (mounted) setState(() {});
        }
      }
    }
  }

  void _setPhase(_Phase p, {_PositionHint? hint}) {
    if (_phase == p && (hint == null || _positionHint == hint)) return;
    if (mounted) {
      setState(() {
        _phase = p;
        if (hint != null) _positionHint = hint;
      });
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _controller;
    if (controller == null) return null;
    final cam = controller.description;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(cam.sensorOrientation);
    } else {
      final deviceRotation =
          _orientationDegrees[controller.value.deviceOrientation];
      if (deviceRotation == null) return null;
      var rot = cam.lensDirection == CameraLensDirection.front
          ? (cam.sensorOrientation + deviceRotation) % 360
          : (cam.sensorOrientation - deviceRotation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(rot);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ─── Capture ─────────────────────────────────────────────────────────

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _capturing || !c.value.isInitialized) return;
    _capturing = true;
    if (mounted) setState(() {});

    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
      final shot = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop<File>(File(shot.path));
    } catch (e) {
      if (!mounted) return;
      _capturing = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chụp lỗi: $e')),
      );
      try {
        await c.startImageStream(_onFrame);
      } catch (_) {}
    }
  }

  // ─── Computed UI state ───────────────────────────────────────────────

  int get _completedCount =>
      _phase == _Phase.neutral ? _challenges.length : _currentIdx;

  /// Remaining seconds of the hard floor (only relevant near the end of challenges).
  int get _remainingSeconds {
    if (_minDurationMet) return 0;
    final elapsed = DateTime.now().difference(_startedAt).inSeconds;
    return math.max(0, _minDuration.inSeconds - elapsed);
  }

  /// Status pill text + color based on the current phase.
  (String, Color) get _statusPillInfo {
    if (_capturing) return ('Đang chụp…', AppColors.emerald);
    if (_phase == _Phase.searching) {
      return switch (_positionHint) {
        _PositionHint.searching => (
            'Đặt khuôn mặt vào khung',
            AppColors.amber,
          ),
        _PositionHint.tooFar => ('Đưa lại gần hơn', AppColors.amber),
        _PositionHint.offCenter => ('Căn giữa khuôn mặt', AppColors.amber),
        _PositionHint.notStraight => (
            'Nhìn thẳng vào camera',
            AppColors.amber,
          ),
        _PositionHint.eyesClosed => ('Mở mắt', AppColors.amber),
        _PositionHint.multipleFaces => (
            'Chỉ chụp 1 khuôn mặt',
            AppColors.amber,
          ),
      };
    }
    if (_phase == _Phase.challenge) {
      final c = _challenges[_currentIdx];
      return (c.prompt, AppColors.emerald);
    }
    // _Phase.neutral
    if (!_minDurationMet) {
      return ('Tốt! Giữ nguyên · còn $_remainingSeconds s', AppColors.emerald);
    }
    return ('Nhìn thẳng để chụp', AppColors.emerald);
  }

  /// 0..1 progress of the current challenge/neutral hold.
  double get _holdProgress {
    if (_phase == _Phase.challenge) {
      return _holdFrames / _challengeHoldThreshold;
    }
    if (_phase == _Phase.neutral) {
      return _holdFrames / _neutralHoldThreshold;
    }
    return 0;
  }

  // ─── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Xác minh khuôn mặt',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _initError != null
          ? _ErrorView(message: _initError!, onRetry: _initCamera)
          : _initializing || _controller == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _FillFrontPreview(controller: _controller!),

                    IgnorePointer(
                      child: CustomPaint(
                        painter: _OvalScrimPainter(),
                      ),
                    ),

                    _OvalFrameOverlay(
                      pillLabel: _statusPillInfo.$1,
                      pillColor: _statusPillInfo.$2,
                      progress: _holdProgress,
                      challengeIcon: _phase == _Phase.challenge
                          ? _challenges[_currentIdx].icon
                          : null,
                      completedCount: _completedCount,
                      totalCount: _challenges.length,
                    ),

                    // Bottom area: progress dots + hint, no shutter button
                    // (anti-bypass — must pass liveness).
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          MediaQuery.of(context).padding.bottom + AppSpacing.md,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.cameraOverlay,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProgressDots(
                              total: _challenges.length,
                              completed: _completedCount,
                              activeIdx: _phase == _Phase.challenge
                                  ? _currentIdx
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Hệ thống xác minh tự động ·\nKhông tua nhanh được',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════

/// Phase machine for the liveness flow.
enum _Phase {
  /// Finding/aligning the face (positioning).
  searching,

  /// Asking the user to perform an action (look up/down/left/right).
  challenge,

  /// 4 actions done, wait for neutral pose + min duration elapsed → capture.
  neutral,
}

/// Specific hint shown during the positioning phase.
enum _PositionHint {
  searching,
  tooFar,
  offCenter,
  notStraight,
  eyesClosed,
  multipleFaces,
}

/// 4 head pose challenges, shuffled randomly each time the scanner opens.
enum _Challenge {
  lookLeft,
  lookRight,
  lookUp,
  lookDown;

  String get prompt => switch (this) {
        _Challenge.lookLeft => 'Quay đầu sang TRÁI',
        _Challenge.lookRight => 'Quay đầu sang PHẢI',
        _Challenge.lookUp => 'Ngẩng đầu LÊN',
        _Challenge.lookDown => 'Cúi đầu XUỐNG',
      };

  IconData get icon => switch (this) {
        _Challenge.lookLeft => Icons.arrow_back_rounded,
        _Challenge.lookRight => Icons.arrow_forward_rounded,
        _Challenge.lookUp => Icons.arrow_upward_rounded,
        _Challenge.lookDown => Icons.arrow_downward_rounded,
      };

  /// Check if the current pose matches this challenge.
  ///
  /// **Front camera + Flutter `camera` plugin convention** (verified empirically):
  /// - User turns head **right** (user's perspective) → headEulerAngleY > 0
  /// - User turns head **left** → headEulerAngleY < 0
  /// - User looks up → headEulerAngleX > 0
  /// - User looks down → headEulerAngleX < 0
  ///
  /// (Previously relied on ML Kit's "viewer's right" docs → wrong because the
  /// display auto-mirrors; users reported reversed behaviour → flipped after
  /// empirical testing.)
  bool matches(double yaw, double pitch) => switch (this) {
        _Challenge.lookLeft => yaw < -_yawThreshold,
        _Challenge.lookRight => yaw > _yawThreshold,
        _Challenge.lookUp => pitch > _pitchThreshold,
        _Challenge.lookDown => pitch < -_pitchThreshold,
      };
}

/// Front camera preview — natural aspect ratio, centered.
///
/// Previously used BoxFit.cover + OverflowBox to fill the screen → on a
/// 9:19.5 display with a 4:3 sensor, the camera was scaled up ~33% and edges
/// cropped → users said "face is too close / zoomed in". Switched to Center +
/// CameraPreview to preserve natural FOV — letterboxes at top/bottom but
/// that's the standard behaviour of the native camera app.
class _FillFrontPreview extends StatelessWidget {
  final CameraController controller;
  const _FillFrontPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(child: CameraPreview(controller));
  }
}

/// 70% black scrim with a centered oval cutout for the face.
class _OvalScrimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ovalW = size.width * 0.72;
    final ovalH = ovalW * 1.32;
    final left = (size.width - ovalW) / 2;
    final top = (size.height - ovalH) / 2;

    final scrim = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addOval(Rect.fromLTWH(left, top, ovalW, ovalH));
    final path = Path.combine(PathOperation.difference, scrim, hole);

    canvas.drawPath(path, Paint()..color = AppColors.cameraScrim);
  }

  @override
  bool shouldRepaint(covariant _OvalScrimPainter old) => false;
}

/// Oval border + status pill + progress arc + big challenge arrow icon.
class _OvalFrameOverlay extends StatefulWidget {
  final String pillLabel;
  final Color pillColor;
  final double progress;
  final IconData? challengeIcon;
  final int completedCount;
  final int totalCount;

  const _OvalFrameOverlay({
    required this.pillLabel,
    required this.pillColor,
    required this.progress,
    required this.challengeIcon,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  State<_OvalFrameOverlay> createState() => _OvalFrameOverlayState();
}

class _OvalFrameOverlayState extends State<_OvalFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final ovalW = size.width * 0.72;
        final ovalH = ovalW * 1.32;
        final left = (size.width - ovalW) / 2;
        final top = (size.height - ovalH) / 2;

        return IgnorePointer(
          child: Stack(
            children: [
              // Oval border + progress arc
              Positioned(
                left: left,
                top: top,
                width: ovalW,
                height: ovalH,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    return CustomPaint(
                      painter: _OvalBorderPainter(
                        color: widget.pillColor,
                        progress: widget.progress.clamp(0.0, 1.0),
                        pulse: _pulseCtrl.value,
                      ),
                    );
                  },
                ),
              ),

              // Big arrow icon centered in the oval — direction hint for the
              // current challenge. Pulses to grab attention.
              if (widget.challengeIcon != null)
                Positioned(
                  left: left,
                  top: top,
                  width: ovalW,
                  height: ovalH,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final scale = 1.0 + _pulseCtrl.value * 0.12;
                        return Transform.scale(
                          scale: scale,
                          child: Icon(
                            widget.challengeIcon,
                            size: 96,
                            color: widget.pillColor.withValues(alpha: 0.85),
                            shadows: const [
                              Shadow(
                                color: Color(0x80000000),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Status pill above the oval.
              Positioned(
                left: 0,
                right: 0,
                top: top - 56,
                child: Center(
                  child: _StatusPill(
                    label: widget.pillLabel,
                    color: widget.pillColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OvalBorderPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double pulse;

  _OvalBorderPainter({
    required this.color,
    required this.progress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Dashed oval border (subtle, breathing alpha).
    final breathing = 0.4 + pulse * 0.3;
    final basePaint = Paint()
      ..color = color.withValues(alpha: breathing)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()..addOval(rect);
    final metrics = path.computeMetrics();
    for (final pm in metrics) {
      double d = 0;
      while (d < pm.length) {
        canvas.drawPath(pm.extractPath(d, d + 8), basePaint);
        d += 16;
      }
    }

    // Progress arc — tracks the current challenge/neutral hold progress.
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      const start = -1.5708; // -π/2 (top)
      final sweep = progress * 6.2832; // 2π
      canvas.drawArc(rect.deflate(2), start, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OvalBorderPainter old) =>
      old.color != color || old.progress != progress || old.pulse != pulse;
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: AppColors.cameraStatusPillBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4 progress dots at the bottom — shows how many challenges are complete.
class _ProgressDots extends StatelessWidget {
  final int total;
  final int completed;
  final int? activeIdx;

  const _ProgressDots({
    required this.total,
    required this.completed,
    required this.activeIdx,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < completed;
        final isActive = activeIdx == i;
        final color = isDone
            ? AppColors.emerald
            : isActive
                ? AppColors.amber
                : Colors.white24;
        return Container(
          width: isActive ? 28 : 18,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
