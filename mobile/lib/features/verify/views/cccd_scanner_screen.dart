import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/models/verify_enums.dart';
import '../utils/cccd_image_cropper.dart';

/// Full-screen scanner cho CCCD.
///
/// Khác `CCCDCaptureScreen` (gọi `image_picker` mở camera native), screen này
/// dựng `CameraPreview` ngay trong app + frame overlay đúng tỉ lệ CCCD +
/// ML Kit text recognition để auto-shutter khi nhận diện đủ keyword.
///
/// Pop về parent với `File?` (cropped) — null nếu user huỷ.
class CCCDScannerScreen extends StatefulWidget {
  final CCCDSide side;

  const CCCDScannerScreen({super.key, required this.side});

  @override
  State<CCCDScannerScreen> createState() => _CCCDScannerScreenState();
}

class _CCCDScannerScreenState extends State<CCCDScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  TextRecognizer? _recognizer;
  bool _initializing = true;
  String? _initError;

  // Detection state.
  bool _processing = false;
  DateTime _lastProcessAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveDetects = 0;
  bool _capturing = false;
  _Status _status = _Status.searching;

  // Auto-capture sau khi detect ổn định ~1.2s (~6 frames @ 200ms throttle).
  static const int _detectThreshold = 6;
  static const Duration _processInterval = Duration(milliseconds: 200);
  static const double _frameWidthFraction = 0.86;

  // Map device orientation → degrees (Android cần để compute rotation).
  static const _orientationDegrees = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    await _recognizer?.close();
    _recognizer = null;
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
      final rear = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      final controller = CameraController(
        rear,
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
          _initError = 'Không khởi tạo được camera: $e';
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
      final recognized = await _recognizer?.processImage(input);
      if (recognized == null || !mounted) return;

      final hit = _matchesCccd(recognized.text, widget.side);
      if (hit) {
        _consecutiveDetects++;
        if (_consecutiveDetects >= _detectThreshold) {
          await _capture();
        } else {
          _setStatus(_Status.detected);
        }
      } else {
        _consecutiveDetects = 0;
        _setStatus(_Status.searching);
      }
    } catch (e) {
      // Bỏ qua frame lỗi — frame sau sẽ thử lại.
      if (kDebugMode) debugPrint('[scanner] frame err: $e');
    } finally {
      _processing = false;
    }
  }

  /// Match keyword đặc trưng của CCCD VN (in cả tiếng Việt + English line).
  ///
  /// Yêu cầu ≥ 2 hit để giảm false positive (tránh trigger khi camera quay
  /// random text ngoài CCCD).
  bool _matchesCccd(String text, CCCDSide side) {
    final upper = text.toUpperCase();

    const frontKeywords = [
      'CĂN CƯỚC CÔNG DÂN',
      'CAN CUOC CONG DAN',
      'CITIZEN IDENTITY',
      'IDENTITY CARD',
      'SOCIALIST REPUBLIC',
      'CỘNG HÒA XÃ HỘI',
      'HỌ VÀ TÊN',
      'FULL NAME',
      'NGÀY SINH',
      'DATE OF BIRTH',
      'QUỐC TỊCH',
      'NATIONALITY',
    ];

    const backKeywords = [
      'ĐẶC ĐIỂM NHÂN DẠNG',
      'PERSONAL IDENTIFICATION',
      'NGÀY, THÁNG, NĂM',
      'DATE, MONTH, YEAR',
      'CỤC TRƯỞNG',
      'DIRECTOR GENERAL',
      'BỘ CÔNG AN',
      'MINISTRY OF PUBLIC SECURITY',
      'NƠI THƯỜNG TRÚ',
      'PLACE OF RESIDENCE',
    ];

    final keywords =
        side == CCCDSide.front ? frontKeywords : backKeywords;
    var hits = 0;
    for (final k in keywords) {
      if (upper.contains(k)) {
        hits++;
        if (hits >= 2) return true;
      }
    }
    return false;
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _controller;
    if (controller == null) return null;
    final cam = controller.description;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation =
          InputImageRotationValue.fromRawValue(cam.sensorOrientation);
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

  // ─── Capture + crop ──────────────────────────────────────────────────

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _capturing || !c.value.isInitialized) return;
    _capturing = true;
    _setStatus(_Status.capturing);

    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
      final shot = await c.takePicture();
      final cropped = await CCCDImageCropper.cropToCccdFrame(
        File(shot.path),
        frameWidthFraction: _frameWidthFraction,
      );
      if (!mounted) return;
      Navigator.of(context).pop<File>(cropped ?? File(shot.path));
    } catch (e) {
      if (!mounted) return;
      _capturing = false;
      _setStatus(_Status.searching);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chụp lỗi: $e')),
      );
      // Restart stream để user thử lại.
      try {
        await c.startImageStream(_onFrame);
      } catch (_) {}
    }
  }

  void _setStatus(_Status s) {
    if (_status == s) return;
    if (mounted) setState(() => _status = s);
  }

  // ─── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.side == CCCDSide.front
              ? 'Quét CCCD mặt trước'
              : 'Quét CCCD mặt sau',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Live preview — fill screen, crop edges if cần.
                        _FillCameraPreview(controller: _controller!),

                        // Dark scrim với cutout ở giữa.
                        IgnorePointer(
                          child: CustomPaint(
                            painter: _ScrimPainter(
                              frameWidthFraction: _frameWidthFraction,
                              aspect: CCCDImageCropper.aspectRatio,
                            ),
                          ),
                        ),

                        // Frame overlay (corners + scan line + status pill).
                        _FrameOverlay(
                          frameWidthFraction: _frameWidthFraction,
                          aspect: CCCDImageCropper.aspectRatio,
                          status: _status,
                          progress: _consecutiveDetects / _detectThreshold,
                        ),

                        // Bottom shutter bar.
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              MediaQuery.of(context).padding.bottom +
                                  AppSpacing.md,
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
                            child: Row(
                              children: [
                                const Spacer(),
                                _ShutterButton(
                                  onTap: _capturing ? null : _capture,
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Tự động chụp\nkhi nhận diện',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Helpers — preview, scrim, frame overlay, shutter button, status enum
// ═══════════════════════════════════════════════════════════════════════

enum _Status { searching, detected, capturing }

/// CameraPreview với BoxFit.cover (thay vì FittedBox default thường để chừa
/// letterbox đen). Giữ tỉ lệ camera, nếu thừa thì crop.
class _FillCameraPreview extends StatelessWidget {
  final CameraController controller;
  const _FillCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    if (preview == null) return CameraPreview(controller);

    // previewSize trả về theo sensor (landscape). Trên portrait UI, swap
    // width/height để FittedBox cover đúng chiều preview thực tế.
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final pw = isPortrait ? preview.height : preview.width;
    final ph = isPortrait ? preview.width : preview.height;

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: pw,
            height: ph,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

/// Vẽ scrim đen mờ phủ toàn screen, trừ vùng cutout CCCD ở center.
class _ScrimPainter extends CustomPainter {
  final double frameWidthFraction;
  final double aspect;

  _ScrimPainter({
    required this.frameWidthFraction,
    required this.aspect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameW = size.width * frameWidthFraction;
    final frameH = frameW / aspect;
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameW, frameH),
      const Radius.circular(16),
    );

    final scrim = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(rect);
    final path = Path.combine(PathOperation.difference, scrim, hole);

    final paint = Paint()..color = AppColors.cameraScrim;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter old) =>
      old.frameWidthFraction != frameWidthFraction || old.aspect != aspect;
}

/// Overlay corner brackets + scan line + status pill ở phía trên frame.
class _FrameOverlay extends StatefulWidget {
  final double frameWidthFraction;
  final double aspect;
  final _Status status;
  final double progress; // 0..1, dùng cho progress bar khi detected

  const _FrameOverlay({
    required this.frameWidthFraction,
    required this.aspect,
    required this.status,
    required this.progress,
  });

  @override
  State<_FrameOverlay> createState() => _FrameOverlayState();
}

class _FrameOverlayState extends State<_FrameOverlay>
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final frameW = size.width * widget.frameWidthFraction;
        final frameH = frameW / widget.aspect;
        final left = (size.width - frameW) / 2;
        final top = (size.height - frameH) / 2;

        final cornerColor = switch (widget.status) {
          _Status.searching => AppColors.amber,
          _Status.detected => AppColors.emerald,
          _Status.capturing => AppColors.emerald,
        };

        return IgnorePointer(
          child: Stack(
            children: [
              // Frame border gọn (1px) + corner brackets.
              Positioned(
                left: left,
                top: top,
                width: frameW,
                height: frameH,
                child: Stack(
                  children: [
                    // Subtle border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cornerColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                    ),
                    // 4 corners
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _Corner(color: cornerColor),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _Corner(color: cornerColor, rotate: 1),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _Corner(color: cornerColor, rotate: 2),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _Corner(color: cornerColor, rotate: 3),
                    ),
                    // Scan line
                    AnimatedBuilder(
                      animation: _scanCtrl,
                      builder: (_, __) {
                        return Positioned(
                          left: 12,
                          right: 12,
                          top: 12 + (frameH - 24) * _scanCtrl.value,
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  cornerColor.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Progress bar dưới đáy frame khi đang detect
                    if (widget.status == _Status.detected)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: widget.progress.clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(cornerColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Status pill phía trên frame
              Positioned(
                left: 0,
                right: 0,
                top: top - 44,
                child: Center(child: _StatusPill(status: widget.status)),
              ),

              // Hint dưới frame
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: top + frameH + 16,
                child: Center(
                  child: Text(
                    'Đặt CCCD vào khung · Giữ thẳng · Đủ ánh sáng',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
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

class _StatusPill extends StatelessWidget {
  final _Status status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _Status.searching => ('Đang tìm CCCD…', AppColors.amber),
      _Status.detected => ('Đã thấy — Giữ yên', AppColors.emerald),
      _Status.capturing => ('Đang chụp…', AppColors.emerald),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final int rotate;
  const _Corner({required this.color, this.rotate = 0});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: rotate,
      child: SizedBox(
        width: 22,
        height: 22,
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
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.color != color;
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ShutterButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
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
