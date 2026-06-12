import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../utils/camera_mlkit_input.dart';
import '../utils/face_analysis_space.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ─── Pose thresholds (degrees) — top-level để `_Challenge.matches()` truy cập ───
const double _yawThreshold = 14.0;
const double _pitchThreshold = 10.0;
const double _neutralTolerance = 12.0;

/// Full-screen selfie scanner với **liveness challenge** + min 3s gate.
///
/// Anti-bot/anti-replay flow:
/// 1. User vào → tìm khuôn mặt + đảm bảo quality (centered, large, eyes open).
/// 2. 4 thao tác liveness được **shuffle ngẫu nhiên** mỗi lần (trái/phải/lên/xuống)
///    để bot pre-record không thể vượt.
/// 3. Mỗi thao tác giữ pose ~0.4s (3 frames @ 120ms) mới count.
/// 4. Sau 4 thao tác → user về neutral pose → hệ thống chụp.
/// 5. **Hard floor 3s**: nếu user qua nhanh hơn → chờ đến 3s mới
///    cho phép capture.
///
/// Pop về parent với `File?` (raw selfie, không crop — face match cần vùng quanh).
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

  // Min duration hard floor — start ngay khi screen open, không phụ thuộc
  // vào tốc độ thao tác. Nếu user xong sớm → countdown overlay.
  static const Duration _minDuration = Duration(seconds: 3);
  late final DateTime _startedAt;
  Timer? _minDurationTimer;
  bool _minDurationMet = false;
  Timer? _tickTimer; // 1 Hz tick để re-render countdown

  // ── Detection thresholds ────────────────────────────────────────────
  static const Duration _processInterval = Duration(milliseconds: 120);
  static const int _challengeHoldThreshold = 3; // ~0.36s giữ pose
  static const int _neutralHoldThreshold = 3; // ~0.36s neutral final

  // Pose thresholds — declared top-level (xem `_yawThreshold` etc. đầu file)
  // để `_Challenge.matches()` enum cũng dùng được cùng giá trị.

  // Face quality (initial gate trước khi vào challenge).
  static const double _minFaceFraction = 0.16;
  static const double _maxOffsetX = 0.38;
  static const double _maxOffsetY = 0.42;
  static const double _minEyeOpenProb = 0.4;

  _Phase _phase = _Phase.searching;
  _PositionHint _positionHint = _PositionHint.searching;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Shuffle 4 challenges — mỗi lần mở scanner thứ tự khác nhau.
    _challenges = [..._Challenge.values]..shuffle(math.Random.secure());
    _startedAt = DateTime.now();

    // Hard floor 3s: timer chạy độc lập với thao tác.
    _minDurationTimer = Timer(_minDuration, () {
      if (mounted) setState(() => _minDurationMet = true);
    });
    // Tick mỗi giây để re-render countdown text (chỉ khi sắp xong).
    // Dừng timer ngay khi _minDurationMet = true để không setState vô ích.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_minDurationMet) {
        _tickTimer?.cancel();
        return;
      }
      setState(() {});
    });

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.12,
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
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: false,
          enableContours: false,
          enableTracking: false,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.12,
        ),
      );
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
        ResolutionPreset.high,
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
      final input = cameraImageToMlKitInput(_controller!, image);
      if (input == null) return;
      final faces = await _detector?.processImage(input);
      if (!mounted) return;

      _processFrame(
        faces ?? const [],
        image: image,
        input: input,
      );
      setState(() {});
    } catch (e) {
      if (kDebugMode) debugPrint('[selfie scanner] frame err: $e');
    } finally {
      _processing = false;
    }
  }

  /// Phase machine driver — gọi mỗi frame (~200ms).
  void _processFrame(
    List<Face> faces, {
    required CameraImage image,
    required InputImage input,
  }) {
    final controller = _controller;
    if (controller == null) return;

    final space = FaceAnalysisSpace.fromStream(
      rawWidth: image.width,
      rawHeight: image.height,
      rotation: input.metadata?.rotation ?? InputImageRotation.rotation0deg,
      isFrontCamera:
          controller.description.lensDirection == CameraLensDirection.front,
    );
    // ── Guard: phải có đúng 1 mặt ──
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

    // ── Phase 1: positioning — đảm bảo face quality OK trước khi vào challenge ──
    if (_phase == _Phase.searching) {
      final faceFraction = space.faceSizeFraction(box);
      if (faceFraction < _minFaceFraction) {
        _setPhase(_Phase.searching, hint: _PositionHint.tooFar);
        return;
      }
      final center = space.centerInPreviewSpace(box);
      final dx = (center.dx - space.width / 2).abs() / space.width;
      final dy = (center.dy - space.height / 2).abs() / space.height;
      if (dx > _maxOffsetX || dy > _maxOffsetY) {
        _setPhase(_Phase.searching, hint: _PositionHint.offCenter);
        return;
      }
      if (leftEye < _minEyeOpenProb || rightEye < _minEyeOpenProb) {
        _setPhase(_Phase.searching, hint: _PositionHint.eyesClosed);
        return;
      }
      // Yêu cầu ban đầu nhìn thẳng → tránh user "cheat" bằng cách giữ nguyên
      // pose trùng với challenge đầu.
      if (yaw.abs() > _neutralTolerance || pitch.abs() > _neutralTolerance) {
        _setPhase(_Phase.searching, hint: _PositionHint.notStraight);
        return;
      }
      // Quality OK → enter challenge phase.
      _setPhase(_Phase.challenge);
      _holdFrames = 0;
      return;
    }

    // ── Phase 2: challenge sequencing ──
    if (_phase == _Phase.challenge) {
      // Vẫn cần thấy mặt — không cần strict quality.
      final current = _challenges[_currentIdx];
      if (current.matches(yaw, pitch)) {
        _holdFrames++;
        if (_holdFrames >= _challengeHoldThreshold) {
          // Challenge done — advance hoặc move to neutral phase.
          _holdFrames = 0;
          if (_currentIdx + 1 >= _challenges.length) {
            _setPhase(_Phase.neutral); // setState bên trong _setPhase
          } else {
            if (mounted) setState(() => _currentIdx++); // một setState duy nhất
          }
        }
      } else {
        if (_holdFrames != 0) {
          _holdFrames = 0;
        }
      }
      return;
    }

    // ── Phase 3: final neutral pose ──
    if (_phase == _Phase.neutral) {
      final isNeutral = yaw.abs() <= _neutralTolerance &&
          pitch.abs() <= _neutralTolerance &&
          leftEye >= _minEyeOpenProb &&
          rightEye >= _minEyeOpenProb;
      if (isNeutral) {
        _holdFrames++;
        if (_holdFrames >= _neutralHoldThreshold && _minDurationMet) {
          _capture();
        }
      } else if (_holdFrames != 0) {
        _holdFrames = 0;
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
      AppToast.error(context, 'Chụp lỗi: $e');
      try {
        await c.startImageStream(_onFrame);
      } catch (_) {}
    }
  }

  // ─── Computed UI state ───────────────────────────────────────────────

  int get _completedCount =>
      _phase == _Phase.neutral ? _challenges.length : _currentIdx;

  /// Số giây còn lại của hard floor 3s (chỉ relevant khi sắp/đã xong challenges).
  int get _remainingSeconds {
    if (_minDurationMet) return 0;
    final elapsed = DateTime.now().difference(_startedAt).inSeconds;
    return math.max(0, _minDuration.inSeconds - elapsed);
  }

  /// Status pill text + color theo phase hiện tại.
  (String, Color) _statusPillInfo(BuildContext context) {
    final success = AppColors.success;
    final warning = AppColors.warning;
    if (_capturing) return ('Đang chụp…', success);
    if (_phase == _Phase.searching) {
      return switch (_positionHint) {
        _PositionHint.searching => (
            'Đặt khuôn mặt vào khung',
            warning,
          ),
        _PositionHint.tooFar => ('Đưa lại gần hơn', warning),
        _PositionHint.offCenter => ('Căn giữa khuôn mặt', warning),
        _PositionHint.notStraight => (
            'Nhìn thẳng vào camera',
            warning,
          ),
        _PositionHint.eyesClosed => ('Mở mắt', warning),
        _PositionHint.multipleFaces => (
            'Chỉ chụp 1 khuôn mặt',
            warning,
          ),
      };
    }
    if (_phase == _Phase.challenge) {
      final c = _challenges[_currentIdx];
      return (c.prompt, success);
    }
    // _Phase.neutral
    if (!_minDurationMet) {
      return ('Tốt! Giữ nguyên · còn $_remainingSeconds s', success);
    }
    return ('Nhìn thẳng để chụp', success);
  }

  /// 0..1 progress của challenge/neutral hold hiện tại.
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
                      pillLabel: _statusPillInfo(context).$1,
                      pillColor: _statusPillInfo(context).$2,
                      progress: _holdProgress,
                      challengeIcon: _phase == _Phase.challenge
                          ? _challenges[_currentIdx].icon
                          : null,
                      completedCount: _completedCount,
                      totalCount: _challenges.length,
                    ),

                    // Bottom area: progress dots + hint, không có shutter button
                    // (anti-bypass — phải đi qua liveness).
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

/// Phase machine của liveness flow.
enum _Phase {
  /// Đang tìm/canh khuôn mặt (positioning).
  searching,

  /// Đang yêu cầu user thực hiện thao tác (look up/down/left/right).
  challenge,

  /// 4 thao tác xong, chờ neutral pose + min 3s elapsed → capture.
  neutral,
}

/// Hint cụ thể trong phase positioning.
enum _PositionHint {
  searching,
  tooFar,
  offCenter,
  notStraight,
  eyesClosed,
  multipleFaces,
}

/// 4 head pose challenges, shuffle ngẫu nhiên mỗi lần mở scanner.
enum _Challenge {
  lookLeft,
  lookRight,
  lookUp,
  lookDown;

  /// Nhãn + mũi tên khớp [matches] trên front cam (ML Kit yaw đảo so với
  /// góc nhìn user — label gắn theo thao tác thực tế, không theo tên enum).
  String get prompt => switch (this) {
        _Challenge.lookLeft => 'Quay đầu sang PHẢI',
        _Challenge.lookRight => 'Quay đầu sang TRÁI',
        _Challenge.lookUp => 'Ngẩng đầu LÊN',
        _Challenge.lookDown => 'Cúi đầu XUỐNG',
      };

  IconData get icon => switch (this) {
        _Challenge.lookLeft => Icons.arrow_back_rounded,
        _Challenge.lookRight => Icons.arrow_forward_rounded,
        _Challenge.lookUp => Icons.arrow_upward_rounded,
        _Challenge.lookDown => Icons.arrow_downward_rounded,
      };

  bool matches(double yaw, double pitch) => switch (this) {
        _Challenge.lookLeft => yaw > _yawThreshold,
        _Challenge.lookRight => yaw < -_yawThreshold,
        _Challenge.lookUp => pitch > _pitchThreshold,
        _Challenge.lookDown => pitch < -_pitchThreshold,
      };
}

/// Front camera preview — natural aspect ratio, centered.
///
/// Trước đây dùng BoxFit.cover + OverflowBox để fill toàn screen → trên màn
/// 9:19.5 với sensor 4:3 thì camera bị scale up ~33%, crop edges → user
/// thấy "quá sát mặt / bị zoom". Chuyển sang Center + CameraPreview để giữ
/// natural FOV — có letterbox đen trên/dưới nhưng đó là behavior chuẩn của
/// app camera native.
class _FillFrontPreview extends StatelessWidget {
  final CameraController controller;
  const _FillFrontPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(child: CameraPreview(controller));
  }
}

/// Scrim đen 70% với cutout oval ở center cho khuôn mặt.
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

              // Big arrow icon ở center oval — direction hint cho current
              // challenge. Pulse để thu hút sự chú ý.
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

              // Status pill phía trên oval
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

    // Progress arc — chạy theo hold progress của challenge/neutral hiện tại.
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

/// 4 progress dots ở bottom — show số challenge đã xong.
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
            ? AppColors.success
            : isActive
                ? AppColors.warning
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
