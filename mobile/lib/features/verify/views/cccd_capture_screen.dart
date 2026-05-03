import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/status_strip.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/verify_enums.dart';
import '../utils/camera_picker.dart';
import 'cccd_scanner_screen.dart';
import 'widgets/camera_frame_overlay.dart';
import 'widgets/verify_app_bar.dart';

/// Screen 2 — Chụp CCCD (mặt trước hoặc mặt sau).
///
/// Một screen handle cả 2 side qua [CCCDSide] arg. Step 1/4 = front, 2/4 = back.
class CCCDCaptureScreen extends ConsumerStatefulWidget {
  final CCCDSide side;
  final bool isResubmit;

  const CCCDCaptureScreen({
    super.key,
    this.side = CCCDSide.front,
    this.isResubmit = false,
  });

  @override
  ConsumerState<CCCDCaptureScreen> createState() => _CCCDCaptureScreenState();
}

class _CCCDCaptureScreenState extends ConsumerState<CCCDCaptureScreen> {
  bool _uploading = false;

  bool get _isFront => widget.side == CCCDSide.front;
  int get _currentStep => _isFront ? 1 : 2;
  String get _stepLabel => _isFront ? 'Mặt trước CCCD' : 'Mặt sau CCCD';

  Future<void> _pickFromCamera() async {
    // Mở in-app scanner (live preview + ML Kit auto-detect) thay vì camera
    // hệ thống. Scanner pop về với File đã crop theo khung CCCD.
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => CCCDScannerScreen(side: widget.side),
        fullscreenDialog: true,
      ),
    );
    if (file != null && mounted) await _upload(file);
  }

  Future<void> _pickFromGallery() async {
    if (!mounted) return;
    final image = await CameraPicker.fromGallery(context);
    if (image != null) await _upload(File(image.path));
  }

  Future<void> _upload(File file) async {
    setState(() => _uploading = true);
    try {
      final controller =
          ref.read(verifyFlowControllerProvider.notifier);
      final result = _isFront
          ? await controller.uploadCCCDFront(file)
          : await controller.uploadCCCDBack(file);

      if (!mounted) return;

      if (result.confidence < 0.8) {
        _showSnack(
          'OCR chưa rõ (${(result.confidence * 100).round()}%). Vui lòng chụp lại.',
          isWarning: true,
        );
        return;
      }

      _navigateNext();
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        _showSnack(msg, isWarning: false);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _navigateNext() {
    if (_isFront) {
      context.pushReplacement('/verify/cccd-back');
    } else {
      context.pushReplacement('/verify/selfie');
    }
  }

  void _showSnack(String msg, {required bool isWarning}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isWarning ? colors.warning : colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: VerifyAppBar(
        overline: 'BƯỚC $_currentStep/4 · VERIFY CCCD',
        title: _stepLabel,
        currentStep: _currentStep,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              120, // chừa chỗ cho buttons fixed bottom
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isFront
                      ? 'Đặt CCCD mặt trước vào khung. Đảm bảo ánh sáng đủ và không bị bóng phản chiếu.'
                      : 'Đặt CCCD mặt sau vào khung. Đảm bảo nét, đọc được hình chip và mã QR.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CameraFrameOverlay(
                  hintTitle: 'Đặt CCCD vào khung',
                  hintSubtitle: 'Chụp tự động khi đủ rõ',
                ).animate().fadeIn(duration: 320.ms),
                const SizedBox(height: AppSpacing.md),
                const StatusStrip(
                  icon: Icons.info_outline,
                  label: 'Lưu ý quan trọng',
                  subtitle:
                      'CCCD còn hiệu lực · Không che các góc · Không reflect ánh sáng',
                  variant: StatusStripVariant.info,
                ),
                if (widget.isResubmit) ...[
                  const SizedBox(height: AppSpacing.sm),
                  StatusStrip(
                    icon: Icons.refresh,
                    label: 'Bổ sung từ lần trước',
                    subtitle:
                        'Admin yêu cầu chụp lại item này — chụp rõ nét hơn.',
                    variant: StatusStripVariant.warning,
                  ),
                ],
              ],
            ),
          ),

          // Bottom action bar (fixed)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border:
                    Border(top: BorderSide(color: colors.borderDefault)),
              ),
              child: Row(
                children: [
                  _IconButton(
                    icon: Icons.photo_library_outlined,
                    onTap: _uploading ? null : _pickFromGallery,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _uploading ? null : _pickFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined,
                            size: 18),
                        label: const Text('Mở camera'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_uploading) const _UploadingOverlay(),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 50,
        height: 52,
        decoration: BoxDecoration(
          color: colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: colors.textPrimary),
      ),
    );
  }
}

class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: AppColors.cameraOverlay,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.bgSurfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingWidget(),
              const SizedBox(height: 12),
              Text(
                'Đang phân tích CCCD...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
