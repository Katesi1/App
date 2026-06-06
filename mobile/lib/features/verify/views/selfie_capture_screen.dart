import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import 'selfie_scanner_screen.dart';
import 'widgets/camera_frame_overlay.dart';
import 'widgets/verify_app_bar.dart';

/// Screen 3 — Selfie + face match check.
class SelfieCaptureScreen extends ConsumerStatefulWidget {
  final bool isResubmit;
  const SelfieCaptureScreen({super.key, this.isResubmit = false});

  @override
  ConsumerState<SelfieCaptureScreen> createState() =>
      _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends ConsumerState<SelfieCaptureScreen> {
  bool _uploading = false;

  Future<void> _capture() async {
    // Mở in-app selfie scanner (front cam + Face Detection auto-shutter)
    // thay vì camera hệ thống.
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => const SelfieScannerScreen(),
        fullscreenDialog: true,
      ),
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await ref.read(verifyFlowControllerProvider.notifier).uploadSelfie(file);
      await ref.read(verifyFlowControllerProvider.notifier).submitForApproval();
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      context.pushReplacement('/verify/pending');
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final ocr = state.cccdFront?.ocrResult;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: const VerifyAppBar(
        overline: 'BƯỚC 3/4 · VERIFY CCCD',
        title: 'Selfie xác minh khuôn mặt',
        currentStep: 3,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ocr != null)
                  _CCCDInfoCard(name: ocr.fullName, cccd: ocr.cccdNumber),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Chụp selfie để so khớp khuôn mặt với ảnh trên CCCD.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SelfieFrameOverlay(hintText: 'Đặt khuôn mặt vào khung')
                    .animate()
                    .fadeIn(duration: 320.ms),
                const SizedBox(height: AppSpacing.md),
                const _TipsCard(),
              ],
            ),
          ),
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
                border: Border(top: BorderSide(color: colors.borderDefault)),
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _uploading ? null : _capture,
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Bắt đầu chụp selfie'),
                ),
              ),
            ),
          ),
          if (_uploading) const _SelfieUploadingOverlay(),
        ],
      ),
    );
  }
}

class _CCCDInfoCard extends StatelessWidget {
  final String? name;
  final String? cccd;
  const _CCCDInfoCard({this.name, this.cccd});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successBgDark,
        border: Border.all(color: AppColors.successBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.successBorder,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 18, color: colors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CCCD đã xác minh',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: colors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name ?? '—',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                if (cccd != null)
                  Text(
                    cccd!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  static const _tips = [
    'Ánh sáng đủ, tránh ngược sáng',
    'Tháo kính, khẩu trang',
    'Nhìn thẳng vào camera',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MẸO SELFIE THÀNH CÔNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          ..._tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check, size: 14, color: colors.success),
                  const SizedBox(width: 8),
                  Text(
                    t,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
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

class _SelfieUploadingOverlay extends StatelessWidget {
  const _SelfieUploadingOverlay();

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
                'Đang so khớp khuôn mặt...',
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
