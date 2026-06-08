import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/status_strip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/verify_enums.dart';
import 'widgets/status_timeline.dart';
import 'widgets/verify_format.dart';

/// Screen 6 — Pending approval.
///
/// Polls status every 30s. On `approved` → push trial active screen; on
/// `rejected` → push rejected screen.
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen>
    with WidgetsBindingObserver {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kick the first poll earlier than 30s so the UI feels responsive.
    Future.microtask(_check);
    _startPolling();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App backgrounded → stop polling to avoid draining battery (10800 extra
    // requests if the user leaves the screen open overnight). Resume + run a
    // single check when foregrounded.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _poll?.cancel();
      _poll = null;
    } else if (state == AppLifecycleState.resumed && _poll == null) {
      _check();
      _startPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        // Sync user.kycStatus → 'approved' so the dashboard banner disappears
        // right after the user navigates back (no pull-to-refresh needed).
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        context.pushReplacement('/verify/approved');
      } else if (status == VerifyStatus.rejected) {
        _poll?.cancel();
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        context.pushReplacement('/verify/rejected');
      }
    } catch (_) {
      // silent retry
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final paidAt = state.paymentSession != null
        ? VerifyFormat.time(DateTime.now())
        : '14:35';

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        // Màn này có thể vào không còn stack cũ (vd context.go từ payment gate /
        // pushReplacement từ selfie) → back tự fallback về dashboard thay vì kẹt.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
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
              'Đang chờ admin duyệt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 320.ms),
            const SizedBox(height: 4),
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
                  subtitle: '$paidAt hôm nay',
                  status: TimelineStepStatus.done,
                ),
                TimelineStep(
                  title: 'Thanh toán đã nhận',
                  subtitle:
                      '${state.selectedPlan?.tier.displayName ?? "Pro"} ${state.billingCycle == BillingCycle.yearly ? "1 năm" : "1 tháng"} · $paidAt',
                  status: TimelineStepStatus.done,
                ),
                const TimelineStep(
                  title: 'Admin đang xét duyệt',
                  subtitle: 'Dự kiến hoàn tất trong 24h',
                  status: TimelineStepStatus.current,
                ),
                const TimelineStep(
                  title: 'Bắt đầu trial 7 ngày',
                  subtitle: 'Sau khi được duyệt',
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
              label: 'Liên hệ hỗ trợ qua email',
              subtitle: AppConstants.supportEmail,
              variant: StatusStripVariant.info,
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri(
                          scheme: 'tel',
                          path: AppConstants.supportPhone,
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.phone_outlined, size: 16),
                      label: const Text('Liên hệ HT'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.borderDefault),
                        foregroundColor: colors.textBrand,
                      ),
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Về tổng quan'),
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
