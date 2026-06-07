import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/user_model.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/status_strip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/verify_enums.dart';
import '../utils/kyc_access.dart';
import 'widgets/status_timeline.dart';
import 'widgets/verify_format.dart';

/// Screen 6 — Pending approval.
///
/// Polling status mỗi 8s. Khi nhận `approved` → chọn gói & thanh toán,
/// nhận `rejected` → push rejected screen.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Kick first poll sớm hơn 30s để mock cảm thấy responsive
    Future.microtask(_check);
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final status = await ref
          .read(verifyFlowControllerProvider.notifier)
          .checkApprovalStatus();
      if (!mounted) return;
      if (status == VerifyStatus.approved) {
        _poll?.cancel();
        // Sync user.kycStatus → 'approved' để dashboard banner biến mất ngay
        // sau khi user navigate về (không phải pull-to-refresh).
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        context.go(UserModel.subscriptionEntryRoute);
      } else if (status == VerifyStatus.rejected) {
        _poll?.cancel();
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        context.go('/verify/rejected');
      }
    } catch (_) {
      // silent retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? user?.phone ?? '—';
    final submittedAt = state.cccdFront?.uploadedAt ?? DateTime.now();
    final submittedLabel = VerifyFormat.time(submittedAt);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => returnToDashboardAfterKyc(context, ref),
        ),
        title: Text(
          'Hồ sơ đã gửi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            _HeroIcon().animate().scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đã hoàn tất xác minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 320.ms),
            const SizedBox(height: 4),
            Text(
              'Đang chờ admin duyệt',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.brandSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 260.ms, duration: 320.ms),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Hồ sơ sẽ được duyệt trong vòng '),
                  TextSpan(
                    text: '24 giờ',
                    style: TextStyle(
                      color: colors.brandSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: '. Bạn sẽ nhận thông báo khi xong.'),
                ],
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 320.ms, duration: 320.ms),
            const SizedBox(height: AppSpacing.lg),

            // Timeline
            StatusTimeline(
              steps: [
                TimelineStep(
                  title: 'CCCD xác minh',
                  subtitle: '$submittedLabel hôm nay',
                  status: TimelineStepStatus.done,
                ),
                const TimelineStep(
                  title: 'Selfie so khớp mặt',
                  subtitle: 'Hoàn tất',
                  status: TimelineStepStatus.done,
                ),
                const TimelineStep(
                  title: 'Gửi hồ sơ',
                  subtitle: 'Đã nộp đủ ảnh',
                  status: TimelineStepStatus.done,
                ),
                const TimelineStep(
                  title: 'Admin đang xét duyệt',
                  subtitle: 'Dự kiến hoàn tất trong 24h',
                  status: TimelineStepStatus.current,
                ),
                const TimelineStep(
                  title: 'Chọn gói và thanh toán',
                  subtitle: 'Sau khi được duyệt',
                  status: TimelineStepStatus.pending,
                ),
                const TimelineStep(
                  title: 'Bắt đầu trial 7 ngày',
                  subtitle: 'Sau khi thanh toán thành công',
                  status: TimelineStepStatus.pending,
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 320.ms)
                .slideY(begin: 0.06, end: 0),

            const SizedBox(height: AppSpacing.md),
            StatusStrip(
              icon: Icons.mail_outline,
              label: 'Thông báo qua email',
              subtitle: 'Sẽ gửi tới $email',
              variant: StatusStripVariant.info,
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/profile/help'),
                      icon: const Icon(Icons.support_agent_outlined, size: 18),
                      label: const Text('Liên hệ admin'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () =>
                          returnToDashboardAfterKyc(context, ref),
                      icon: const Icon(Icons.dashboard_outlined, size: 18),
                      label: const Text('Trang tổng quan'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.infoBgDark,
              border: Border.all(color: colors.borderDefault),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.access_time, size: 36, color: colors.brandLight),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colors.brandSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.bgCanvas, width: 3),
              ),
              child: Icon(Icons.check, size: 12, color: AppColors.darkBg),
            ),
          ),
        ],
      ),
    );
  }
}
